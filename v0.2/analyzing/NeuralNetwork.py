# Title: NeuralNetwork.py
# Authors: Sofiia Khutorna, Rem D'Ambrosio
# Created: 2024-07-09
   
import torch   
import torch.nn as nn
import torch.optim as optim
import numpy as np 

class NeuralNetwork(nn.Module):
    def __init__(self):
        super().__init__()
        self.dropout1 = nn.Dropout(0.3)
        self.dropout2 = nn.Dropout(0.4)
        self.dropout3 = nn.Dropout(0.5) 

        self.layer1 = nn.Linear(18, 324)
        self.act1 = nn.ReLU()
        self.layer2 = nn.Linear(324, 162)
        self.act2 = nn.ReLU() 
        self.layer3 = nn.Linear(162, 54)
        self.act3 = nn.ReLU()
        self.output = nn.Linear(54, 1)
        
        self.sigmoid = nn.Sigmoid()
        
    def forward(self, x):
        #x = self.dropout1(x)
        x = self.act1(self.layer1(x))
        # x = self.dropout1(x)
        x = self.act2(self.layer2(x))
        # x = self.dropout2(x)
        x = self.act3(self.layer3(x))
        # x = self.dropout3(x)
        # x = self.sigmoid(self.output(x))
        x = self.output(x)
        return x