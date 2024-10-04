# Title: Trainer.py
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-07-09
# Description: 

import torch  
import torch.nn as nn
import torch.optim as optim
import pandas as pd
import numpy as np
from torch.utils.data import DataLoader, TensorDataset
from NeuralNetwork import NeuralNetwork


class Trainer():  
    def __init__(self, path):
        self.device = 'cuda' if torch.cuda.is_available() else 'cpu' 
        self.parameters = [ 'temp_avg', 'temp_avg_stdev', 'temp_avg_slope',
                            'temp_max', 'temp_max_stdev', 'temp_max_slope',
                            'cpu_avg', 'cpu_avg_stdev', 'cpu_avg_slope',
                            'cpu_max', 'cpu_max_stdev', 'cpu_max_slope',
                            'latency_avg', 'latency_avg_stdev', 'latency_avg_slope', 
                            'latency_max', 'latency_max_stdev', 'latency_max_slope']
        
        train_path = path + "/training/training_v0.2_2023-1-1_2024-8-1.csv"
        val_path = path + "/training/validation_v0.2_2023-1-1_2024-8-1.csv"
 
        self.train_data = self.to_dataframe(train_path)
        self.val_data = self.to_dataframe(val_path)
        

    def create_model(self):
        '''Creates and returns a new NeuralNetwork'''
        model = NeuralNetwork()
        return model 
    

    def train_model(self, model, epochs):
        '''Trains a neural network using a numpy data given
            Parameters:     model: NeuralNetwork   
                            data: numpy array of training data
            Returns:        none''' 

        inputs = self.parameters
        outputs = ['failing'] 

        x = torch.tensor(self.train_data[inputs].values,dtype=torch.float)
        y = torch.tensor(self.train_data[outputs].values,dtype=torch.float)
        dataset = TensorDataset(x, y)
        dataloader = DataLoader(dataset, batch_size=2069, shuffle=True, drop_last=True)
        
        val_x = torch.tensor(self.val_data[inputs].values,dtype=torch.float)
        val_y = torch.tensor(self.val_data[outputs].values,dtype=torch.float)
        val_dataset = dataset = TensorDataset(val_x, val_y)
        val_dataloader = DataLoader(val_dataset, batch_size=1000, shuffle=True, drop_last=True)

        model.to(self.device)
        #criterion = torch.nn.BCELoss()
        
        pos_weight = torch.tensor([0.03])  # Adjust the weight as needed
        criterion = nn.BCEWithLogitsLoss(pos_weight=pos_weight)

        # learning rate parameters
        optimizer = optim.Adam(model.parameters(), lr=0.001)
        scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, 'min', patience=15, factor=0.1, min_lr=1e-7)
        
        # early stopping parameters
        stop_patience = 30
        best_performance = float('inf')
        bad_streak = 0

        # MASTER LOOP
        for epoch in range(epochs):
            true_positive = 0    
            false_positive = 0
            false_negative = 0  
            true_negative = 0   
            total_loss = 0.0
            val_loss = 0.0
             
            current_lr = optimizer.param_groups[0]['lr']
            print(f'=== Epoch {epoch+1}: Current LR: {current_lr} ===')

            # TRAINING LOOP
            for batch_x, batch_y in dataloader:
                optimizer.zero_grad()                                                   # predict
                batch_x, batch_y = batch_x.to(self.device), batch_y.to(self.device)
                y_pred = model(batch_x)
                y_actual = batch_y[:, 0].unsqueeze(1)
                loss = criterion(y_pred, y_actual)                                      # optimize
                total_loss += loss.item()
                loss.backward() 
                optimizer.step()

                # y_pred_binary = torch.round(y_pred).cpu().detach().numpy()              # convert predictions to binary, move to CPU
                min_value = y_pred.min()
                max_value = y_pred.max()
                y_pred_binary = (torch.sigmoid(y_pred) > 0.5).float().cpu().detach().numpy()
                y_actual_binary = y_actual.cpu().detach().numpy()
                
                true_positive += ((y_pred_binary == 1) & (y_actual_binary == 1)).sum()
                false_positive += ((y_pred_binary == 1) & (y_actual_binary == 0)).sum()
                false_negative += ((y_pred_binary == 0) & (y_actual_binary == 1)).sum()
                true_negative += ((y_pred_binary == 0) & (y_actual_binary == 0)).sum()

            # VALIDATION LOOP
            val_tp = 0
            val_fp = 0
            
            for batch_x, batch_y in val_dataloader:
                batch_x, batch_y = batch_x.to(self.device), batch_y.to(self.device)
                y_pred = model(batch_x)
                y_actual = batch_y[:, 0].unsqueeze(1)

                loss = criterion(y_pred, y_actual)
                val_loss += loss.item()

                min_value = y_pred.min()
                max_value = y_pred.max()
                y_pred_binary = (y_pred - min_value) / (max_value - min_value)
                y_pred_binary = torch.round(y_pred_binary).cpu().detach().numpy()
                y_actual_binary = y_actual.cpu().detach().numpy()

                val_tp += ((y_pred_binary == 1) & (y_actual_binary == 1)).sum()
                val_fp += ((y_pred_binary == 1) & (y_actual_binary == 0)).sum()

            val_precision = val_tp / (val_tp + val_fp)
            val_performance = 1 - val_precision

            # learning rate and early stopping
            if total_loss < best_performance:
                best_performance = total_loss
                bad_streak = 0
            else:
                bad_streak += 1
                if bad_streak >= stop_patience:
                    print(f"========== EARLY STOP ==========")
                    break

            scheduler.step(total_loss)

            # outputs
            accuracy = (true_positive + true_negative) / (true_positive + true_negative + false_positive + false_negative)
            precision = true_positive / (true_positive + false_positive) if (true_positive + false_positive) > 0 else 0
            recall = true_positive / (true_positive + false_negative) if (true_positive + false_negative) > 0 else 0
            f1_score = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
            
            print(f"Total Loss at {epoch+1}: {total_loss}")
            print(f"Val Loss: {val_loss}, Val Precision: {val_precision}")
            print(f"Accuracy: {accuracy:.4f}, Precision: {precision:.4f}, Recall: {recall:.4f}, F1 Score: {f1_score:.4f}")
            print(f"True Positive: {true_positive}, False Positive: {false_positive}, True Negative: {true_negative}, False Negative: {false_negative}")


# ========================================================================================================================================================
# I/O FUNCTIONS
# ========================================================================================================================================================


    def to_dataframe(self, path):
        columns = ['failing', 'model'] + self.parameters + ['name']
        df = pd.read_csv(path, names=columns)
        return df
    

    def save_model(self, model, path):
        '''Saves trained NeuralNetwork model model to file
           Parameters:     model: NeuralNetwork, trained model to be saved
                           path: str, path to the model file
           Returns:        None'''
        torch.save(model.state_dict(), path)


    def load_model(self, path):
        ''' Loads trained NeuralNetwork model from file 
            Parameters:     path: str, path to the model file
            Returns:        model: NeuralNetwork object'''
        
        model = NeuralNetwork()                      # create empty model
        model.load_state_dict(torch.load(path))      # load a static dict with trained parameters from file to the model
        model.train()                                # set model to evaluation mode
        return model