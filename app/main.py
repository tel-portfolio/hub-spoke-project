import yfinance as yf
import pyodbc
import os
from dotenv import load_dotenv
from datetime import datetime, timedelta

# Load environment variables
load_dotenv()

# --- CONFIGURATION ---
symbols = ['TSM', 'BRK-B', 'WMT', 'LLY', 'JPM', 'V', 'XOM', 'JNJ', 'MA', 'ORCL']
conn_str = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    f"SERVER={os.getenv('DB_SERVER', 'localhost')},1433;"
    f"DATABASE={os.getenv('DB_NAME', 'PhoenixTrading')};"
    f"UID={os.getenv('DB_USER', 'sa')};"
    f"PWD={os.getenv('DB_PASSWORD')};"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("Connected to Database.")
except Exception as e:
    print(f"DB Connection Failed: {e}")
    exit()

# --- STEP 1: PRUNE OLD DATA (7 Day Limit) ---
print("Pruning signals older than 7 days...")
try:
    cursor.execute("DELETE FROM Signals WHERE GeneratedDate < DATEADD(day, -7, GETDATE())")
    conn.commit()
except Exception as e:
    print(f"Pruning failed: {e}")

# --- STEP 2: GET CURRENT POSITIONS ---
# We need to know what we own to decide between BUY vs HOLD vs SELL
owned_tickers = set()
try:
    cursor.execute("SELECT Ticker FROM Positions WHERE Shares > 0")
    rows = cursor.fetchall()
    for row in rows:
        owned_tickers.add(row[0])
    print(f"Current Positions: {owned_tickers}")
except Exception as e:
    print(f"Could not fetch positions: {e}")

# --- STEP 3: FETCH DATA & ANALYZE ---
print("Downloading market data...")
data = yf.download(symbols, period="1mo", auto_adjust=True)
closes = data['Close']
last_3_days = closes.tail(3)

print("\n--- Generating Signals ---")

for ticker in symbols:
    if ticker not in last_3_days.columns:
        print(f"[ERROR] No data for {ticker}")
        continue

    # Get Prices
    prices = last_3_days[ticker]
    day_before = prices.iloc[0]
    yesterday  = prices.iloc[1]
    today      = prices.iloc[2]
    
    # Identify Trend
    trend = "CHOPPY"
    if today > yesterday and yesterday > day_before:
        trend = "UP"
    elif today < yesterday and yesterday < day_before:
        trend = "DOWN"

    # Contextual Logic (Trend + Position = Signal)
    final_signal = "HOLD"
    
    if trend == "UP":
        # Only BUY if we don't already own it
        if ticker not in owned_tickers:
            final_signal = "BUY"
        else:
            final_signal = "HOLD (Already Owned)"
            
    elif trend == "DOWN":
        # Only SELL if we actually own it
        if ticker in owned_tickers:
            final_signal = "SELL"
        else:
            final_signal = "WAIT (Don't Own)"

    print(f"{ticker}: {day_before:.2f} -> {yesterday:.2f} -> {today:.2f} | Trend: {trend} | Signal: {final_signal}")

    # --- STEP 4: STORE SIGNAL ---
    try:
        cursor.execute(
            "INSERT INTO Signals (Ticker, SignalType, GeneratedDate) VALUES (?, ?, ?)",
            ticker, final_signal, datetime.now()
        )
        conn.commit()
    except Exception as e:
        print(f"Error saving signal for {ticker}: {e}")

conn.close()
print("\n--- Done ---")