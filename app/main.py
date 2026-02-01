# main.py

import yfinance


#Get list of stocks
#Use List for right now

#Update the closing price of the stock in the database. This way we are saving the data so we make fewer calls to the yfinance API.

#Check if the closing price of the stock today is higher than the closing price of the stock yesterday and the day before (If so, mark as BUY).

#Check if the price of a stock is below the price it was yesterday, which is below the price it was the day before (If so, mark SELL).

# Update the database with the BUY and SELL signals.