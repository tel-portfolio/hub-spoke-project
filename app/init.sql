USE PhoenixTrading;
GO

-- =============================================
-- 1. ACCOUNTS TABLE
-- Stores non-sensitive identifiers. Keys live in Key Vault.
-- =============================================
IF OBJECT_ID('dbo.Accounts', 'U') IS NOT NULL DROP TABLE dbo.Accounts;

CREATE TABLE Accounts (
    AccountID INT IDENTITY(1,1) PRIMARY KEY,
    AlpacaID VARCHAR(64) NOT NULL UNIQUE,  -- The public Account ID from Alpaca
    AccountName VARCHAR(50) NOT NULL,      -- e.g., 'Retirement', 'Speculative'
    IsActive BIT DEFAULT 1
);
GO

-- Seed the two accounts (Replace with your actual Alpaca IDs later)
INSERT INTO Accounts (AlpacaID, AccountName) VALUES 
('PA-ACCOUNT-1', 'Primary Strategy'),
('PA-ACCOUNT-2', 'Experimental');
GO


-- =============================================
-- 2. SIGNALS TABLE (The "Queue")
-- The Nightly Script inserts here. K8s Workers read from here.
-- =============================================
IF OBJECT_ID('dbo.Signals', 'U') IS NOT NULL DROP TABLE dbo.Signals;

CREATE TABLE Signals (
    SignalID INT IDENTITY(1,1) PRIMARY KEY,
    Ticker VARCHAR(10) NOT NULL,
    SignalType VARCHAR(10) NOT NULL,       -- 'BUY', 'SELL'
    GeneratedDate DATETIME DEFAULT GETDATE(),
    
    -- Workflow Status for K8s Workers
    ProcessingStatus VARCHAR(20) DEFAULT 'PENDING', -- 'PENDING', 'COMPLETED', 'FAILED'
    ProcessedAt DATETIME NULL
);
GO

-- Index to help K8s workers find pending jobs quickly
CREATE INDEX IX_Signals_Pending ON Signals(ProcessingStatus) WHERE ProcessingStatus = 'PENDING';
GO


-- =============================================
-- 3. POSITIONS TABLE
-- Tracks what each specific account owns.
-- =============================================
IF OBJECT_ID('dbo.Positions', 'U') IS NOT NULL DROP TABLE dbo.Positions;

CREATE TABLE Positions (
    PositionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT FOREIGN KEY REFERENCES Accounts(AccountID),
    Ticker VARCHAR(10) NOT NULL,
    Shares DECIMAL(10, 4) DEFAULT 0,
    AvgCost DECIMAL(10, 2) DEFAULT 0,
    LastUpdated DATETIME DEFAULT GETDATE(),

    -- Ensure one record per Ticker per Account
    CONSTRAINT UQ_Account_Ticker UNIQUE(AccountID, Ticker)
);
GO


-- =============================================
-- 4. TRANSACTIONS TABLE (The Audit Trail)
-- Workers insert here after a successful execution.
-- =============================================
IF OBJECT_ID('dbo.Transactions', 'U') IS NOT NULL DROP TABLE dbo.Transactions;

CREATE TABLE Transactions (
    TransactionID INT IDENTITY(1,1) PRIMARY KEY,
    AccountID INT FOREIGN KEY REFERENCES Accounts(AccountID),
    SignalID INT FOREIGN KEY REFERENCES Signals(SignalID), -- Links back to the logic that caused this
    Ticker VARCHAR(10) NOT NULL,
    Action VARCHAR(10) NOT NULL, -- 'BUY', 'SELL'
    Shares DECIMAL(10, 4) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    TotalValue AS (Shares * Price), -- Computed column
    Timestamp DATETIME DEFAULT GETDATE()
);
GO