# Title: Grabber.py
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-06-05
# Description: v0.2

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
        
        self.healthy_samples = []
        self.failing_samples = []
        self.training = []
        self.validation = []

        self.stats = ["temp_avg", "temp_max", "cpu_avg", "cpu_max", "latency_avg", "latency_max"]
        
        self.stats_full = ["temp_avg", "temp_avg_stdev", "temp_avg_slope",
                           "temp_max", "temp_max_stdev", "temp_max_slope",
                           "cpu_avg", "cpu_avg_stdev", "cpu_avg_slope",
                           "cpu_max", "cpu_max_stdev", "cpu_max_slope",
                           "latency_avg", "latency_avg_stdev", "latency_avg_slope",
                           "latency_max", "latency_max_stdev", "latency_max_slope"]
        
        self.upper_limits = {key: float('-inf') for key in self.stats_full}
        self.lower_limits = {key: float('inf') for key in self.stats_full}

        self.multiple_failure_days = {}                 # for tracking sites which have already produced a failing sample on a given day

        input_dir = self.database_dir + "/formatted/"
        input_filenames = [f for f in os.listdir(input_dir) if os.path.isfile(os.path.join(input_dir, f))]

        for file in input_filenames:
            print("...Reading from ", file, "...")
            database = self.file_to_db(file)
            switches = self.grab_switches(database)
            self.switches_to_samples(switches)

        self.healthy_ratio = len(self.healthy_samples) / len(self.failing_samples)

        self.equal_set()
        self.validation_set()


    def file_to_db(self, file):
        '''Reads file and returns a dict with all info
            Parameters: file: string representing filename
            Return:     database : json/dictionary object holding all info about swithces'''
        
        formatted_dir = self.database_dir + "/formatted/"
        path = formatted_dir + file

        with open(path) as f:
            database = json.load(f)

        return database

    def grab_switches(self, database):
        '''Grabs only switches from database and throws away invalid switches
            Parameters: database: json/dictionary object holding all info about switches
            Return:     database: dictionary with valid switches only'''

        for key in list(database.keys()):
            # if we don't have enough data points to form a single sample or it is juniper, we don't care about this switch
            if database[key]["model"] == "juniper" or len(database[key]["ping_latency_max"]) < self.sample_len:     
                del database[key]    
                continue 

            #del database[key]["switch_name"]
            #del database[key]["site_code"]

        return database 
  
    def switches_to_samples(self, switches):
        '''Scans switches and grabs all valid samples for training
            Parameters: switches: dict of Switch objects
            Return:     none'''

        sample_len = self.sample_len
        data_len = 579                      

        healthy_count = 0
        failing_count = 0

        skip = []                           # these periods will not be used as healthy or failing data
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
                            
                            if valid:                                   # if sample is valid, find out if it's going to fail or not before creation
                                if (end_day == data_len):                    
                                    if (str(end_day) in events.keys()): # if sample period is leading up to natural final event, failing
                                        failing = True
                                        failing_count += 1
                                    else:                               # if leading up to synthetic final event, not failing
                                        failing = False
                                        healthy_count += 1
                                elif (dist_from_event < 1):             # if leading up to an event, failing
                                    failing = True
                                    failing_count += 1
                                else:                                   # otherwise, not failing
                                    failing = False
                                    healthy_count += 1
                            
                                if not self.is_multiple_failure(switch, end_day, failing):       # check if other devices have failed at that site on that day
                                    self.make_sample(switch, end_day, failing)

                        end_day = end_day - sample_len                  # ready to check next potential sample in this period
                        dist_from_event += 1
                
                last_event_day = end_day                                # all potential samples in period have been checked; end day is now start of next period

        print("...Grabbed ", healthy_count, " healthy and ", failing_count, " will fail...")
        return
    

    def is_multiple_failure(self, switch, event_day, failing):
        if failing:
            if switch["site_code"] in self.multiple_failure_days:
                if event_day in self.multiple_failure_days[switch["site_code"]]:
                    return True                                                     # something already failed at this day at this site
                else:
                    self.multiple_failure_days[switch["site_code"]].add(event_day)
                    return False                                                    # nothing has failed at that site on that day yet
            else:
                self.multiple_failure_days[switch["site_code"]] = {event_day}
                return False                                                        # nothing has failed at that site yet
        else:
            return False                                                            # switch is healthy


    def is_valid_sample(self, switch, day) -> bool:  
        '''Check if this potential sample is valid by looking at preceding sample_len days
            Parameters: switch : Switch object
                        day : int, day of observation start
            Return:     valid : boolean, indicating if sample is valid or not'''

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
  
          
    def make_sample(self, switch, day, failing):
        '''Creates a new sample object, add it to training set and resets limits for stats if needed
            Parameters: switch : Switch object
                        day : int, day that we start iteration on
                        failing : boolean indicating if switch is going to fail or not
            Return:   none'''  
        
        sample_len = self.sample_len
        name = switch["switch_name"]
        model = switch["model"]
        temp_avg = [float(switch["temp_avg"][str(x)]) for x in range(day - sample_len, day)]                    # create lists of stats
        temp_max = [int(switch["temp_max"][str(x)]) for x in range(day - sample_len, day)]
        cpu_avg = [float(switch["cpu_avg"][str(x)]) for x in range(day - sample_len, day)]
        cpu_max = [int(switch["cpu_max"][str(x)]) for x in range(day - sample_len, day)]
        latency_avg = [int(switch["ping_latency_avg"][str(x)]) for x in range(day - sample_len, day)]
        latency_max = [int(switch["ping_latency_max"][str(x)]) for x in range(day - sample_len, day)]

        new_sample = Sample(failing, name, model, temp_avg, temp_max, cpu_avg, cpu_max, latency_avg, latency_max)     # pass these lists to create a new sample
    
        self.update_limits(new_sample)                                                                  # update sample limits based on the new sample

        if failing:                                                                                     # if this sample is at the end of training time period
            self.failing_samples.append(new_sample)                                                     # add sample to validation/testing set
        else:
            self.healthy_samples.append(new_sample)                                                     # add the rest to the traing set
        return

 
    def update_limits(self, sample):
        ''' Checks if any stat in sample is most extreme yet, and updates limits accordingly
            Parameters: sample: Sample object      
            Return:     none'''
        for stat, limit in self.upper_limits.items():                    # update top limit
            value = getattr(sample, stat)
            if value > limit:
                self.upper_limits[stat] = value
        
        for stat, limit in self.lower_limits.items():                    # update bottom limits
            value = getattr(sample, stat)
            if value < limit:
                self.lower_limits[stat] = value

        return
            

    def normalize_sample(self, sample) -> list:
        '''Normalize Sample values to 0-1 range and convert from object to list
            Parameters: sample : Sample object
            Return:     list   : formatted list with all info about the sample'''
        list = []

        if sample.failing: 
            list.append(1)
        else:
            list.append(0)
        
        list.append(sample.model)
        
        for stat in self.stats_full:                                # normalize each stat of sample based on the upper and lower limits
            val = getattr(sample, stat)
            top = self.upper_limits[stat]
            bot = self.lower_limits[stat]
            list.append( (val - bot) / (top - bot) )

        list.append(sample.name)
        return list


    def equal_set(self):
        ''' Create training dataset with 50% healthy and 50% failing samples'''
        training_quota = len(self.failing_samples) * 0.9
        while (len(self.training) < training_quota * 2):           
            index_1 = random.randint(0, len(self.failing_samples)-1)
            index_2 = random.randint(0, len(self.healthy_samples)-1)
            self.training.append(self.failing_samples.pop(index_1))
            self.training.append(self.healthy_samples.pop(index_2))
        return


    def validation_set(self):
        ''' Create validation dataset with skewed ratio of healthy to failing samples'''
        while (self.failing_samples):
            index_1 = random.randint(0, len(self.failing_samples)-1)
            self.validation.append(self.failing_samples.pop(index_1))
            i = 0
            while (i < self.healthy_ratio):
                index_2 = random.randint(0, len(self.healthy_samples)-1)
                self.validation.append(self.healthy_samples.pop(index_2))
                i += 1
        return


    def samples_to_file(self, dataset_name):  
        '''Writes all proccessed sample information into files
        Parameters:     dataset_name: string indicating part of filename of a dataset 
        Return:         none'''

        output_path = self.database_dir + "/training/training_" + dataset_name + ".csv"
        
        with open(output_path, 'w', newline ='') as file:  
            writer = csv.writer(file)
            while self.training:
                sample = self.training.pop()
                row = self.normalize_sample(sample)
                writer.writerow(row)

        output_path = self.database_dir + "/training/validation_" + dataset_name + ".csv"

        with open(output_path, 'w', newline ='') as file:
            writer = csv.writer(file)
            while self.validation:
                sample = self.validation.pop()
                row = self.normalize_sample(sample)
                writer.writerow(row)

        return
    