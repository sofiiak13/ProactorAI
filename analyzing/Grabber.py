#
# Title: Grabber.py
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-05
# Description: 
# Example: 
#

import os
import json
import csv
import random
from Sample import Sample
import re


class Grabber:
    def __init__(self, database_dir, sample_len):
        self.database_dir = database_dir
        self.sample_len = sample_len
        
        self.training = []
        self.validation = []
        self.small = []

        self.stats = ["temp_avg", "temp_max", "cpu_avg", "cpu_max", "latency_avg", "latency_max"]
        
        self.stats_full = ["temp_avg", "temp_avg_stdev", "temp_avg_slope",
                           "temp_max", "temp_max_stdev", "temp_max_slope",
                           "cpu_avg", "cpu_avg_stdev", "cpu_avg_slope",
                           "cpu_max", "cpu_max_stdev", "cpu_max_slope",
                           "latency_avg", "latency_avg_stdev", "latency_avg_slope",
                           "latency_max", "latency_max_stdev", "latency_max_slope"]
        
        self.upper_limits = {key + "_top": None for key in self.stats_full}
        self.lower_limits = {key + "_bot": None for key in self.stats_full}

        input_dir = self.database_dir + "/formatted/"
        input_filenames = [f for f in os.listdir(input_dir) if os.path.isfile(os.path.join(input_dir, f))]

        # i = 0
        for file in input_filenames:
            print("...Reading from ", file, "...")
            database = self.file_to_db(file)
            switches = self.grab_switches(database)
            self.switches_to_samples(switches)

            # i += 1
            # if (i == 2):
            #     break

        # self.validation_set()
        # self.small_set()


    # Function Name: file_to_db()
    # Example use: 
    # Description:
    #     reads file and returns a dict with all info
    # Parameters: 
    #     file: string representing filename
    # Return:
    #     database : json/dictionary object holding all info about swithces
    def file_to_db(self, file):
        formatted_dir = self.database_dir + "/formatted/"
        path = formatted_dir + file

        with open(path) as f:
            database = json.load(f)

        return database


    # Function Name: grab_switches()
    # Description: grabs only switches from database and throws away invalid switches
    #     
    # Parameters:
    #     database: json/dictionary object holding all info about switches
    # Return:
    #     database: dictionary with valid switches only
    def grab_switches(self, database):

        for key in list(database.keys()):
            # if we don't have enough data points to form a single sample or it is juniper, we don't care about this switch
            if database[key]["model"] == "juniper" or len(database[key]["ping_latency_max"]) < self.sample_len:     
                del database[key]    
                continue 

            del database[key]["switch_name"]
            del database[key]["site_code"]

        return database


    # Function Name: switches_to_samples()
    # Description: scans switches and grabs all valid samples for training
    #      
    # Parameters: 
    #               switches: dict of Switch objects
    # Return:
    #               none
    def switches_to_samples(self, switches):

        sample_len = self.sample_len
        data_len = 346                      

        healthy_count = 0
        unhealthy_count = 0
        skip = []                         # these periods will not be used as healthy or unhealthy data
                                                    # represents desired gap between down-events and healthy periods
        for switch in switches.values():
            events = switch["events"]
            event_days_raw = [int(x) for x in events.keys()]
            event_days = [x for x in event_days_raw if x <= data_len]
            event_days.sort()

            if (len(event_days) == 0 or event_days[-1] != data_len):         # synthesize event at end of observation s.t. we check for
                event_days.append(data_len)                                  # healthy data near end of year, even if event didn't happen
            
            last_event_day = 0

            # identify valid periods for this switch
            for end_day in event_days:  
                
                dist_from_event = 0 

                if (end_day == data_len or events[str(end_day)][0] == "down"):      # if end of period is last day of observation, or any period ending in down event

                    while ( (end_day - last_event_day) >= sample_len ):             # identify valid samples within this period

                        if (dist_from_event not in skip):                           # to create desired gap between down events and healthy periods

                            valid = self.is_valid_sample(switch, end_day)  
                            
                            if valid:                                   # if sample is valid, find out if it's healthy or unhealthy before creation
                                if (end_day == data_len):                    
                                    if (str(end_day) in events.keys()): # if sample period is leading up to natural final event, unhealthy
                                        healthy = False
                                        unhealthy_count += 1
                                    else:                               # if leading up to synthetic final event, healthy
                                        healthy = True
                                        healthy_count += 1
                                elif (dist_from_event < 1):             # if leading up to an event, unhealthy
                                    healthy = False
                                    unhealthy_count += 1
                                else:                                   # otherwise, healthy
                                    healthy = True
                                    healthy_count += 1
                        
                                self.make_sample(switch, end_day, healthy, data_len)

                        end_day = end_day - sample_len               # ready to check next potential sample in this period
                        dist_from_event += 1
                
                last_event_day = end_day                 # all potential samples in period have been checked; end day is now start of next period

        print("...Grabbed ", healthy_count, " healthy and ", unhealthy_count, " unhealthy...")
        return
    

    # Function Name: is_valid_sample()
    # Description: check if this potential sample is valid by looking at preceding sample_len days
    #     
    # Parameters: switch : Switch object
    #             day : day of observation start
    # Return:
    #             valid : boolean indicating if sample is valid or not
    def is_valid_sample(self, switch, day) -> bool:  

        # create shallow copy of stats list, fixing the naming convention issue in our data
        # can remove this later if we fix the data to report values as latency instead of ping_latency
        stats = self.stats[:]
        stats[4] = "ping_latency_avg"
        stats[5] = "ping_latency_max"

        valid = True
        for cur_day in range(day - 1, day - self.sample_len - 1 , -1):
            for stat in stats:                                          # for sample to be valid, all stats must be present
                if str(cur_day) in switch[stat].keys():
                    pass
                else:
                    valid = False
                    return valid
                
        return valid
  
    
    # Function Name: make_sample() 
    # Description: creates a new sample object, add it to training set and resets limits for stats if needed
    #     
    # Parameters: switch : Switch object
    #             day : int day that we start iteration on
    #             healthy : boolean indicating if switch is healthy or not
    # Return:   none
    #             
    def make_sample(self, switch, day, healthy, data_len):
        sample_len = self.sample_len

        model = switch["model"]
        temp_avg = [float(switch["temp_avg"][str(x)]) for x in range(day - sample_len, day)]
        temp_max = [int(switch["temp_max"][str(x)]) for x in range(day - sample_len, day)]
        cpu_avg = [float(switch["cpu_avg"][str(x)]) for x in range(day - sample_len, day)]
        cpu_max = [int(switch["cpu_max"][str(x)]) for x in range(day - sample_len, day)]
        latency_avg = [int(switch["ping_latency_avg"][str(x)]) for x in range(day - sample_len, day)]
        latency_max = [int(switch["ping_latency_max"][str(x)]) for x in range(day - sample_len, day)]

        new_sample = Sample(healthy, model, temp_avg, temp_max, cpu_avg, cpu_max, latency_avg, latency_max)
    
        self.update_limits(new_sample)

        if day == data_len:
            self.validation.append(new_sample)
        else:
            self.training.append(new_sample)
        return


    # Function Name: update_limits()
    # Description: resets upper and lower limits for stats if needed
    #     
    # Parameters: sample: Sample object
    #     
    # Return: none
    #     
    def update_limits(self, sample):
        
        for key, limit in self.upper_limits.items():                    # update top limits
            match = re.search(r"^(.+)_", key)
            stat = match.group(1)
            if not limit or getattr(sample, stat) > limit:
                self.upper_limits[key] = getattr(sample, stat)
        
        for key, limit in self.lower_limits.items():                    # update bottom limits
            match = re.search(r"^(.+)_", key)
            stat = match.group(1)
            if not limit or getattr(sample, stat) < limit:
                self.lower_limits[key] = getattr(sample, stat)

        return
        
            
    # Function Name: normalize_sample()
    # Description: 
    #     normalize Sample values to 0-1 range and convert from object to list
    # Parameters:
    #     sample : Sample object
    # Return:
    #     list   : formatted list with all info about the sample
    def normalize_sample(self, sample) -> list:
        
        list = []

        if sample.healthy:
            list.append(1)
        else:
            list.append(0)
        
        list.append(sample.model)
        
        for stat in self.stats_full:
            top_name = stat + "_top"
            bot_name = stat + "_bot"
            val = getattr(sample, stat)
            top = self.upper_limits[top_name]
            bot = self.lower_limits[bot_name]
            list.append( (val - bot) / (top - bot) ) 

        return list

    
    # Function Name: small_set()
    # Description: Create a smaller dataset with 50% healthy and 50% unhealthy samples 
    #     
    # Parameters: none
    #     
    # Return: none
    #     
    def small_set(self):
        
        size = len(self.training) - 1

        healthy_quota = 5000
        unhealthy_quota = 5000

        while (healthy_quota > 0 or unhealthy_quota > 0):           # while we still have some room left for healthy or unhealthy samples

            index = random.randrange(0, size)                       
            temp = self.training.pop(index)                         # pop a random sample from training set
            size -= 1

            if (temp.healthy == 1):                                 # if it is healthy and we have room, add it to smal set
                if (healthy_quota > 0):
                    self.small.append(temp)
                    healthy_quota -= 1
                else:                                               # else put it back to training set
                    self.training.append(temp)      
            else:
                if (unhealthy_quota > 0):                           # if it is unhealthy and we have room, add it to smal set
                    self.small.append(temp)
                    unhealthy_quota -= 1
                else:                                               # else put it back to training set
                    self.training.append(temp)
        
        return

        
    # Function Name: samples_to_file()
    # Description:
    #     writes all proccessed sample information into files
    # Parameters:
    #     dataset_name: string indicating part of filename of a dataset 
    # Return:
    #     none
    def samples_to_file(self, dataset_name):  

        output_path = self.database_dir + "/training/training_test_" + dataset_name + ".csv"
        
        with open(output_path, 'w', newline ='') as file:  
            writer = csv.writer(file)
            while self.training:
                sample = self.training.pop()
                row = self.normalize_sample(sample)
                writer.writerow(row)

        output_path = self.database_dir + "/training/validation_test_" + dataset_name + ".csv"

        with open(output_path, 'w', newline ='') as file:
            writer = csv.writer(file)
            while self.validation:
                sample = self.validation.pop()
                row = self.normalize_sample(sample)
                writer.writerow(row)

        #output_path = self.database_dir + "/training/training_" + dataset_name + ".csv"

        # with open(output_path, 'w', newline ='') as file:
        #     writer = csv.writer(file)
        #     while self.small:
        #         sample = self.small.pop()
        #         row = self.normalize_sample(sample)
        #         writer.writerow(row)

        return
    