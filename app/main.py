import yfinance as yf

# List of stocks that will be replaced by Excel spreadsheet in storage account.
symbols = ['TSM', 'BRK-B', 'WMT', 'LLY', 'JPM', 'V', 'XOM', 'JNJ', 'MA', 'ORCL']

print("Downloading data from Yahoo Finance...")

#Get last month of data to ensure we have enough information
data = yf.download(symbols, period="1mo", auto_adjust=True)

# Extract Close prices
closes = data['Close']

# Get the last 3 available records (Today, Yesterday, Day before Yesterday)
last_3_days = closes.tail(3)

# 3. Analyze each stock
for ticker in symbols:
    
    # Error Handling: Check if we actually got data for this specific stock
    if ticker not in last_3_days.columns:
        print(f"[ERROR] No data found for {ticker}")
        continue

    # Grab the 3 prices for this stock
    prices = last_3_days[ticker]
    
    day_before = prices.iloc[0]
    yesterday  = prices.iloc[1]
    today      = prices.iloc[2]
    
    # --- DATABASE TODO 1: Insert Closing Price ---
    # SQL: "INSERT INTO StockPrices (Ticker, Price, Date) VALUES (?, ?, ?)"
    # cursor.execute(query, ticker, today, datetime.now())
    
    # 4. Determine Signal
    signal = "HOLD" # Default
    
    # BUY Logic: Strictly Increasing
    if today > yesterday and yesterday > day_before:
        signal = "BUY"
        print(f"[{signal}]  {ticker}: Trending UP ({day_before:.2f} -> {yesterday:.2f} -> {today:.2f})")
        
    # SELL Logic: Strictly Decreasing
    elif today < yesterday and yesterday < day_before:
        signal = "SELL"
        print(f"[{signal}] {ticker}: Trending DOWN ({day_before:.2f} -> {yesterday:.2f} -> {today:.2f})")
    
    else:
        print(f"[WAIT]  {ticker} is choppy.")

    # --- DATABASE TODO 2: Insert Signal ---
    # Only write to DB if we have a signal? Or always update status?
    # SQL: "UPDATE StockAnalysis SET Signal = ? WHERE Ticker = ?"
    # cursor.execute(query, signal, ticker)

print("\n--- Analysis Complete ---")