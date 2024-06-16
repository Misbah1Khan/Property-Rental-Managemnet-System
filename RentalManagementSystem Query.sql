create database RentalManagement;
use RentalManagement;

create table Property(
propertyID int primary key identity(1,1),
propertyAddress varchar(255),
propertyType varchar(255),
propertyRooms varchar(255),
propertyGarages int,
tenantID int foreign key references Tenant(tenantID),
status varchar(255) check (status in ('EMPTY','RENTED','SOLD'))
);

create table Agents(
agentID int primary key identity(1,1),
agentName varchar(255),
agentPhone varchar(255),
agentAddress varchar(255),
agentFees money
);

create table Tenant(
tenantID int primary key identity(1,1),
agentID int foreign key references Agents(agentID),
tenantName varchar(255) not null,
tenantPhone varchar(255),
CNIC varchar(255),
password int
);

create table Rents(
rentID int primary key identity(1,1),
propertyID int foreign key references Property(propertyID),
tenantID int foreign key references Tenant(tenantID),
RentAmount money,
startDate date,
endDate date
);

create table Invoice(
invoiceID int primary key identity(1,1),
propertyID int foreign key references Property(propertyID),
issueDate date,
dueDate date,
amountDue money,
invoiceType varchar(255) check (invoiceType in ('WATER','ELECTRICITY','GAS','RENT')),
invoiceStatus varchar(255) check (invoiceStatus in ('PAID','UNPAID'))
);

create table Maintenance(
maintenanceID int primary key identity(1,1),
maintenanceTitle varchar(255),
maintenanceDescription varchar(255),
maintenanceCost money,
maintenanceDate date,
propertyID int foreign key references Property(propertyID)
);

create table Transactions(
transactionID int primary key identity(1,1),
transactionDate date,
transactionAmount money,
invoiceID int foreign key references Invoice(invoiceID)
);

create table Notices(
noticeID int primary key identity(1,1),
noticeTitle varchar(255),
noticeDescription varchar(255),
noticeDate date,
propertyID int foreign key references Property(propertyID)
);

create table Applications(
applicationID int primary key identity(1,1),
tenantID int foreign key references Tenant(tenantID),
applicationTitle varchar(255),
applicationDescription varchar(255),
applicationStatus varchar(255) check(applicationStatus in ('COMPLETED','RECEIVED','IN PROGRESS'))
);


create proc insertTransaction
@invoiceID int,@amount money
as
begin
	INSERT INTO Transactions (TransactionDate, transactionAmount, InvoiceID)
    VALUES (CURRENT_TIMESTAMP, @amount, @invoiceID);
	update invoice set invoiceStatus = 'PAID' where invoiceID = @invoiceID;
	end;


create proc createInvoice
@propertyID int, @dueDate date, @amount money, @type varchar(255)
as
begin
	INSERT INTO Invoice (propertyID,issueDate,dueDate, amountDue, invoiceType,invoiceStatus)
	VALUES (@propertyID,CURRENT_TIMESTAMP,@dueDate,@amount,@type,'UNPAID');
	end;

create proc createTenant
@agentID int, @name varchar(255),@phone varchar(255),@cnic varchar(255)
as
begin
	DECLARE @newTenantID int,@password int
	INSERT INTO Tenant (AgentID,tenantName,tenantPhone,CNIC)
	VALUES (@agentID,@name,@phone,@cnic);
	set @newTenantID = SCOPE_IDENTITY();
	set @password= @newTenantID * 2;
	update Tenant set password = @password where tenantID=@newTenantID;
	end;

create proc rentProperty
@tenantID int ,@propertyID int, @rentAmount money, @duration int,@startDate date
as
begin
	declare @endDate date
	UPDATE Property set tenantID = @tenantID,status='RENTED' where propertyID= @propertyID;

	set @endDate = DATEADD(month,@duration,@startDate)
	INSERT INTO Rents (propertyID,tenantID,RentAmount,startDate,endDate)
	VALUES(@propertyID,@tenantID,@rentAmount,@startDate,@endDate)
	end;

create proc createProperty
@address varchar(255),@type varchar(255),@rooms int,@garages int
as
begin
	INSERT INTO Property(propertyAddress,propertyType,propertyRooms,propertyGarages,status)
	VALUES(@address,@type,@rooms,@garages,'EMPTY')
	end;

create proc insertMaintenance
@description varchar(255),@cost money,@date date,@propertyID int,@title varchar(255)
as
begin
	INSERT INTO Maintenance (maintenanceDescription,maintenanceCost,maintenanceDate,propertyID,maintenanceTitle)
	VALUES (@description,@cost,@date,@propertyID,@title)
	end;


create proc createNotice
@description varchar(255),@date date, @propertyID int,@title varchar(255)
as
begin
	INSERT INTO Notices(noticeDescription,noticeDate,propertyID,noticeTitle)
	VALUES(@description,@date,@propertyID,@title)
	end;


create proc insertAgent
@name varchar(255),@phone varchar(255),@address varchar(255),@fees money
as
begin
	INSERT INTO Agents(agentName,agentPhone,agentAddress,agentFees)
	VALUES(@name,@phone,@address,@fees);
	end;

create proc insertApplication
@tenantID int, @description varchar(255),@status varchar(255),@title varchar(255)
as
begin
	INSERT INTO Applications(tenantID,applicationDescription,applicationStatus,applicationTitle)
	VALUES(@tenantID,@description,@status,@title)
	end;

create proc deleteTenant
@tenantID int
as
begin
	delete from Rents where tenantID=@tenantID;
	update Property set tenantID=null where tenantID=@tenantID;
	delete from Applications where tenantID=@tenantID;
	delete from Tenant where tenantID=@tenantID;
	end;

create proc retrieveIncome
as
begin
	SELECT 
    SUM(amountDue) AS TotalCost
FROM 
    Invoice
WHERE
	invoiceType='RENT' and invoiceStatus = 'PAID'
GROUP BY 
    MONTH(dueDate);
	end;

create proc retrieveExpense
as
begin
	SELECT 
    SUM(maintenanceCost) 
FROM 
    Maintenance
GROUP BY 
    MONTH(maintenanceDate);
	end;

create proc deleteRent
@rentID int
as
begin
	declare @propertyID int
	set @propertyID=(select PropertyID from Rents where rentID= @rentID);
	delete from Rents where rentID= @rentID;
	update Property set tenantID = null, status = 'EMPTY' where propertyID = @propertyID
	end;

create proc deleteProperty
@propertyID int
as
begin
	delete from Property where propertyID=@propertyID
	end;

create proc retrievePaidInvoicesOfUser
@userID int
as 
begin
	SELECT i.*
FROM Invoice i
INNER JOIN Property p ON i.propertyID = p.propertyID
WHERE p.tenantID = @userID and invoiceStatus = 'PAID'
end;

create proc retrieveUnpaidInvoicesOfUser
@userID int
as 
begin
	SELECT i.*
FROM Invoice i
INNER JOIN Property p ON i.propertyID = p.propertyID
WHERE p.tenantID = @userID and invoiceStatus = 'UNPAID'
end;

create proc retrievePropertiesOfUser
@userID int
as
begin
	Select property.* from property join rents on property.propertyID=rents.propertyID where property.tenantID= @userID
	end;

create proc retrieveRentedProperties
as
begin
	select * from Property where status = 'RENTED'
	end;

create proc retrieveEmptyProperties
as
begin
	select * from Property where status = 'EMPTY'
	end;

create proc retrieveSoldProperties
as
begin
	select * from Property where status = 'SOLD'
	end;

create proc deleteAgent
@agentID int
as
begin
	update Tenant set agentID=null where agentID=@agentID;
	delete from Agents where agentID=@agentID;
	end;

create proc retrieveApplicationsOfUser
@userID int
as
begin
	select * from Applications where tenantID= @userID
	end;



CREATE TABLE TransactionAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    ActionType VARCHAR(10),
    transactionID INT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_Transactions
ON Transactions
AFTER INSERT, DELETE
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO TransactionAudit (ActionType, transactionID, Timestamp)
        SELECT 'INSERT', i.transactionID, CURRENT_TIMESTAMP
        FROM inserted i;
    END
    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO TransactionAudit (ActionType, transactionID, Timestamp)
        SELECT 'DELETE', d.transactionID, CURRENT_TIMESTAMP
        FROM deleted d;
    END
END;

CREATE TABLE TenantAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    ActionType VARCHAR(10),
    tenantID INT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_Tenant
ON Tenant
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO TenantAudit (ActionType, tenantID, Timestamp)
        SELECT 'INSERT', i.tenantID, CURRENT_TIMESTAMP
        FROM inserted i;
    END
	IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO TenantAudit (ActionType, tenantID, Timestamp)
        SELECT 'UPDATE', i.tenantID, CURRENT_TIMESTAMP
        FROM inserted i;
    END
    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO TenantAudit (ActionType, tenantID, Timestamp)
        SELECT 'DELETE', d.tenantID, CURRENT_TIMESTAMP
        FROM deleted d;
    END
END;

CREATE TABLE PropertyAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    ActionType VARCHAR(10),
    propertyID INT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_Property
ON property
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO PropertyAudit (ActionType, propertyID, Timestamp)
        SELECT 'INSERT', i.propertyID, CURRENT_TIMESTAMP
        FROM inserted i;
    END
	IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO PropertyAudit (ActionType, propertyID, Timestamp)
        SELECT 'UPDATE', i.propertyID, CURRENT_TIMESTAMP
        FROM inserted i;
    END
    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO propertyAudit (ActionType, propertyID, Timestamp)
        SELECT 'DELETE', d.propertyID, CURRENT_TIMESTAMP
        FROM deleted d;
    END
END;

CREATE TABLE RentAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    ActionType VARCHAR(10),
    rentID INT,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER trg_Rents
ON Rents
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO RentAudit (ActionType, rentID, Timestamp)
        SELECT 'INSERT', i.rentID, CURRENT_TIMESTAMP
        FROM inserted i;
    END
	IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO RentAudit (ActionType, rentID, Timestamp)
        SELECT 'UPDATE', i.rentID, CURRENT_TIMESTAMP
        FROM inserted i;
    END

    IF NOT EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO RentAudit (ActionType, rentID, Timestamp)
        SELECT 'DELETE', d.rentID, CURRENT_TIMESTAMP
        FROM deleted d;
    END
END;

-- Insert 10 agents
EXEC insertAgent @name = 'John Smith', @phone = '555-1234', @address = '123 Elm St', @fees = 1000.00;
EXEC insertAgent @name = 'Jane Doe', @phone = '555-5678', @address = '456 Oak St', @fees = 1100.00;
EXEC insertAgent @name = 'Bill Turner', @phone = '555-8765', @address = '789 Pine St', @fees = 1200.00;
EXEC insertAgent @name = 'Anna Johnson', @phone = '555-4321', @address = '321 Maple St', @fees = 1300.00;
EXEC insertAgent @name = 'Mike Brown', @phone = '555-5674', @address = '654 Cedar St', @fees = 1400.00;
EXEC insertAgent @name = 'Emily Davis', @phone = '555-8764', @address = '987 Birch St', @fees = 1500.00;
EXEC insertAgent @name = 'Chris Wilson', @phone = '555-2345', @address = '234 Spruce St', @fees = 1600.00;
EXEC insertAgent @name = 'Karen White', @phone = '555-6789', @address = '567 Fir St', @fees = 1700.00;
EXEC insertAgent @name = 'David Harris', @phone = '555-9876', @address = '890 Ash St', @fees = 1800.00;
EXEC insertAgent @name = 'Susan Clark', @phone = '555-3456', @address = '123 Walnut St', @fees = 1900.00;

-- Insert 10 properties
EXEC createProperty @address = '1 Park Avenue', @type = 'House', @rooms = 3, @garages = 2;
EXEC createProperty @address = '2 River Road', @type = 'Apartment', @rooms = 2, @garages = 1;
EXEC createProperty @address = '3 Forest Lane', @type = 'Condo', @rooms = 4, @garages = 1;
EXEC createProperty @address = '4 Hill Street', @type = 'House', @rooms = 3, @garages = 2;
EXEC createProperty @address = '5 Lake Drive', @type = 'Apartment', @rooms = 2, @garages = 1;
EXEC createProperty @address = '6 Mountain Blvd', @type = 'Condo', @rooms = 4, @garages = 1;
EXEC createProperty @address = '7 Beach Road', @type = 'House', @rooms = 3, @garages = 2;
EXEC createProperty @address = '8 Valley Court', @type = 'Apartment', @rooms = 2, @garages = 1;
EXEC createProperty @address = '9 Sunset Terrace', @type = 'Condo', @rooms = 4, @garages = 1;
EXEC createProperty @address = '10 Ocean Avenue', @type = 'House', @rooms = 3, @garages = 2;

EXEC createProperty @address = '1 Park Avenue', @type = 'House', @rooms = 3, @garages = 2;
EXEC createProperty @address = '2 River Road', @type = 'Apartment', @rooms = 2, @garages = 1;
EXEC createProperty @address = '3 Forest Lane', @type = 'Condo', @rooms = 4, @garages = 1;
EXEC createProperty @address = '4 Hill Street', @type = 'House', @rooms = 3, @garages = 2;

-- Insert 10 tenants
EXEC createTenant @agentID = 1, @name = 'Alice Martin', @phone = '555-1111', @cnic = 'CNIC12345', @propertyID = 1;
EXEC createTenant @agentID = 2, @name = 'Bob Johnson', @phone = '555-2222', @cnic = 'CNIC23456', @propertyID = 2;
EXEC createTenant @agentID = 3, @name = 'Charlie Williams', @phone = '555-3333', @cnic = 'CNIC34567', @propertyID = 3;
EXEC createTenant @agentID = 4, @name = 'Diana Brown', @phone = '555-4444', @cnic = 'CNIC45678', @propertyID = 4;
EXEC createTenant @agentID = 5, @name = 'Edward Davis', @phone = '555-5555', @cnic = 'CNIC56789', @propertyID = 5;
EXEC createTenant @agentID = 6, @name = 'Fiona Wilson', @phone = '555-6666', @cnic = 'CNIC67890', @propertyID = 6;
EXEC createTenant @agentID = 7, @name = 'George Clark', @phone = '555-7777', @cnic = 'CNIC78901', @propertyID = 7;
EXEC createTenant @agentID = 8, @name = 'Hannah Lee', @phone = '555-8888', @cnic = 'CNIC89012', @propertyID = 8;
EXEC createTenant @agentID = 9, @name = 'Ian Harris', @phone = '555-9999', @cnic = 'CNIC90123', @propertyID = 9;
EXEC createTenant @agentID = 10, @name = 'Jack Moore', @phone = '555-0000', @cnic = 'CNIC01234', @propertyID = 10;

-- Rent properties to tenants
EXEC rentProperty @tenantID = 1, @propertyID = 1, @rentAmount = 1200.00, @duration = 12, @startDate = '2024-01-01';
EXEC rentProperty @tenantID = 2, @propertyID = 2, @rentAmount = 1000.00, @duration = 12, @startDate = '2024-02-01';
EXEC rentProperty @tenantID = 3, @propertyID = 3, @rentAmount = 1500.00, @duration = 12, @startDate = '2024-03-01';
EXEC rentProperty @tenantID = 4, @propertyID = 4, @rentAmount = 1300.00, @duration = 12, @startDate = '2024-04-01';
EXEC rentProperty @tenantID = 5, @propertyID = 5, @rentAmount = 1100.00, @duration = 12, @startDate = '2024-05-01';
EXEC rentProperty @tenantID = 6, @propertyID = 6, @rentAmount = 1400.00, @duration = 12, @startDate = '2024-06-01';
EXEC rentProperty @tenantID = 7, @propertyID = 7, @rentAmount = 1200.00, @duration = 12, @startDate = '2024-07-01';
EXEC rentProperty @tenantID = 8, @propertyID = 8, @rentAmount = 1000.00, @duration = 12, @startDate = '2024-08-01';
EXEC rentProperty @tenantID = 9, @propertyID = 9, @rentAmount = 1500.00, @duration = 12, @startDate = '2024-09-01';
EXEC rentProperty @tenantID = 10, @propertyID = 10, @rentAmount = 1300.00, @duration = 12, @startDate = '2024-10-01';

-- Insert 10 invoices
EXEC createInvoice @propertyID = 1, @dueDate = '2024-06-10', @amount = 200.00, @type = 'WATER';
EXEC createInvoice @propertyID = 2, @dueDate = '2024-06-10', @amount = 300.00, @type = 'ELECTRICITY';
EXEC createInvoice @propertyID = 3, @dueDate = '2024-06-10', @amount = 400.00, @type = 'GAS';
EXEC createInvoice @propertyID = 4, @dueDate = '2024-06-10', @amount = 500.00, @type = 'RENT';
EXEC createInvoice @propertyID = 1, @dueDate = '2024-06-10', @amount = 100.00, @type = 'RENT';
EXEC createInvoice @propertyID = 3, @dueDate = '2024-06-10', @amount = 500.00, @type = 'RENT';
EXEC createInvoice @propertyID = 5, @dueDate = '2024-06-10', @amount = 600.00, @type = 'WATER';
EXEC createInvoice @propertyID = 6, @dueDate = '2024-06-10', @amount = 700.00, @type = 'ELECTRICITY';
EXEC createInvoice @propertyID = 7, @dueDate = '2024-06-10', @amount = 800.00, @type = 'GAS';
EXEC createInvoice @propertyID = 8, @dueDate = '2024-06-10', @amount = 900.00, @type = 'RENT';
EXEC createInvoice @propertyID = 9, @dueDate = '2024-06-10', @amount = 1000.00, @type = 'WATER';
EXEC createInvoice @propertyID = 10, @dueDate = '2024-06-10', @amount = 1100.00, @type = 'ELECTRICITY';
EXEC createInvoice @propertyID = 5, @dueDate = '2024-05-10', @amount = 600.00, @type = 'RENT';
EXEC createInvoice @propertyID = 6, @dueDate = '2024-04-10', @amount = 700.00, @type = 'RENT';
EXEC createInvoice @propertyID = 7, @dueDate = '2024-03-10', @amount = 800.00, @type = 'RENT';
EXEC createInvoice @propertyID = 8, @dueDate = '2024-02-10', @amount = 900.00, @type = 'RENT';
EXEC createInvoice @propertyID = 9, @dueDate = '2024-01-10', @amount = 1000.00, @type = 'RENT';
EXEC createInvoice @propertyID = 10, @dueDate = '2024-07-10', @amount = 1100.00, @type = 'RENT';
EXEC createInvoice @propertyID = 1, @dueDate = '2024-08-10', @amount = 200.00, @type = 'RENT';
EXEC createInvoice @propertyID = 2, @dueDate = '2024-09-10', @amount = 300.00, @type = 'RENT';
EXEC createInvoice @propertyID = 3, @dueDate = '2024-10-10', @amount = 400.00, @type = 'RENT';
EXEC createInvoice @propertyID = 3, @dueDate = '2024-11-10', @amount = 400.00, @type = 'RENT';
EXEC createInvoice @propertyID = 4, @dueDate = '2024-12-10', @amount = 500.00, @type = 'RENT';
EXEC createInvoice @propertyID = 1, @dueDate = '2024-05-10', @amount = 100.00, @type = 'RENT';
EXEC createInvoice @propertyID = 3, @dueDate = '2024-07-10', @amount = 500.00, @type = 'RENT';
EXEC createInvoice @propertyID = 5, @dueDate = '2024-03-10', @amount = 600.00, @type = 'RENT';
EXEC createInvoice @propertyID = 10, @dueDate = '2024-06-10', @amount = 1100.00, @type = 'ELECTRICITY';
EXEC createInvoice @propertyID = 5, @dueDate = '2024-05-10', @amount = 600.00, @type = 'RENT';
EXEC createInvoice @propertyID = 6, @dueDate = '2024-04-10', @amount = 700.00, @type = 'RENT';
EXEC createInvoice @propertyID = 7, @dueDate = '2024-03-10', @amount = 800.00, @type = 'RENT';
EXEC createInvoice @propertyID = 8, @dueDate = '2024-02-10', @amount = 900.00, @type = 'RENT';

-- Insert 10 transactions
EXEC insertTransaction @invoiceID = 31, @amount = 200.00;
EXEC insertTransaction @invoiceID = 32, @amount = 300.00;
EXEC insertTransaction @invoiceID = 33, @amount = 400.00;
EXEC insertTransaction @invoiceID = 34, @amount = 500.00;
EXEC insertTransaction @invoiceID = 35, @amount = 600.00;
EXEC insertTransaction @invoiceID = 36, @amount = 700.00;
EXEC insertTransaction @invoiceID = 37, @amount = 800.00;
EXEC insertTransaction @invoiceID = 38, @amount = 900.00;
EXEC insertTransaction @invoiceID = 39, @amount = 1000.00;
EXEC insertTransaction @invoiceID = 40, @amount = 1100.00;
EXEC insertTransaction @invoiceID = 41, @amount = 100.00;
EXEC insertTransaction @invoiceID = 42, @amount = 500.00;
EXEC insertTransaction @invoiceID = 43, @amount = 600.00;
EXEC insertTransaction @invoiceID = 44, @amount = 700.00;
EXEC insertTransaction @invoiceID = 45, @amount = 800.00;
EXEC insertTransaction @invoiceID = 46, @amount = 900.00;
EXEC insertTransaction @invoiceID = 47, @amount = 1000.00;
EXEC insertTransaction @invoiceID = 48, @amount = 1100.00;
EXEC insertTransaction @invoiceID = 49, @amount = 200.00;
EXEC insertTransaction @invoiceID = 50, @amount = 300.00;
EXEC insertTransaction @invoiceID = 51, @amount = 400.00;
EXEC insertTransaction @invoiceID = 52, @amount = 400.00;
EXEC insertTransaction @invoiceID = 53, @amount = 500.00;
EXEC insertTransaction @invoiceID = 54, @amount = 100.00;
EXEC insertTransaction @invoiceID = 55, @amount = 500.00;
EXEC insertTransaction @invoiceID = 56, @amount = 600.00;

-- Insert 10 maintenance records
EXEC insertMaintenance @description = 'Repair roof', @cost = 150.00, @date = '2024-05-15', @propertyID = 1, @title = 'Roof Repair';
EXEC insertMaintenance @description = 'Replace windows', @cost = 200.00, @date = '2024-05-20', @propertyID = 2, @title = 'Window Replacement';
EXEC insertMaintenance @description = 'Fix plumbing', @cost = 250.00, @date = '2024-05-25', @propertyID = 3, @title = 'Plumbing Repair';
EXEC insertMaintenance @description = 'Paint walls', @cost = 300.00, @date = '2024-05-30', @propertyID = 4, @title = 'Interior Painting';
EXEC insertMaintenance @description = 'Clean carpets', @cost = 350.00, @date = '2024-06-04', @propertyID = 5, @title = 'Carpet Cleaning';
EXEC insertMaintenance @description = 'Repair appliances', @cost = 400.00, @date = '2024-06-09', @propertyID = 6, @title = 'Appliance Repair';
EXEC insertMaintenance @description = 'Landscaping', @cost = 450.00, @date = '2024-06-14', @propertyID = 7, @title = 'Landscaping Services';
EXEC insertMaintenance @description = 'Replace HVAC system', @cost = 500.00, @date = '2024-06-19', @propertyID = 8, @title = 'HVAC Replacement';
EXEC insertMaintenance @description = 'Fix electrical wiring', @cost = 550.00, @date = '2024-06-24', @propertyID = 9, @title = 'Electrical Repair';
EXEC insertMaintenance @description = 'Install security system', @cost = 600.00, @date = '2024-06-29', @propertyID = 10, @title = 'Security System Installation';
EXEC insertMaintenance @description = 'Repair roof', @cost = 150.00, @date = '2024-04-15', @propertyID = 1, @title = 'Roof Repair';
EXEC insertMaintenance @description = 'Replace windows', @cost = 200.00, @date = '2024-03-20', @propertyID = 2, @title = 'Window Replacement';
EXEC insertMaintenance @description = 'Fix plumbing', @cost = 250.00, @date = '2024-02-25', @propertyID = 3, @title = 'Plumbing Repair';
EXEC insertMaintenance @description = 'Paint walls', @cost = 300.00, @date = '2024-01-30', @propertyID = 4, @title = 'Interior Painting';
EXEC insertMaintenance @description = 'Clean carpets', @cost = 350.00, @date = '2024-09-04', @propertyID = 5, @title = 'Carpet Cleaning';
EXEC insertMaintenance @description = 'Repair appliances', @cost = 400.00, @date = '2024-10-09', @propertyID = 6, @title = 'Appliance Repair';
EXEC insertMaintenance @description = 'Landscaping', @cost = 450.00, @date = '2024-11-14', @propertyID = 7, @title = 'Landscaping Services';
EXEC insertMaintenance @description = 'Replace HVAC system', @cost = 500.00, @date = '2024-12-19', @propertyID = 8, @title = 'HVAC Replacement';
EXEC insertMaintenance @description = 'Fix electrical wiring', @cost = 550.00, @date = '2024-01-24', @propertyID = 9, @title = 'Electrical Repair';
EXEC insertMaintenance @description = 'Install security system', @cost = 600.00, @date = '2024-02-29', @propertyID = 10, @title = 'Security System Installation';
EXEC insertMaintenance @description = 'Paint walls', @cost = 300.00, @date = '2024-08-30', @propertyID = 4, @title = 'Interior Painting';
EXEC insertMaintenance @description = 'Clean carpets', @cost = 350.00, @date = '2024-07-04', @propertyID = 5, @title = 'Carpet Cleaning';
EXEC insertMaintenance @description = 'Repair appliances', @cost = 400.00, @date = '2024-08-09', @propertyID = 6, @title = 'Appliance Repair';
EXEC insertMaintenance @description = 'Landscaping', @cost = 450.00, @date = '2024-07-14', @propertyID = 7, @title = 'Landscaping Services';
-- Insert 10 notices
EXEC createNotice @description = 'Scheduled maintenance', @date = '2024-06-01', @propertyID = 1, @title = 'Maintenance Notice';
EXEC createNotice @description = 'Community meeting', @date = '2024-06-02', @propertyID = 2, @title = 'Community Meeting';
EXEC createNotice @description = 'Trash pickup schedule', @date = '2024-06-03', @propertyID = 3, @title = 'Trash Schedule';
EXEC createNotice @description = 'Parking restrictions', @date = '2024-06-04', @propertyID = 4, @title = 'Parking Notice';
EXEC createNotice @description = 'Pool closure for cleaning', @date = '2024-06-05', @propertyID = 5, @title = 'Pool Maintenance';
EXEC createNotice @description = 'Upcoming event', @date = '2024-06-06', @propertyID = 6, @title = 'Event Notice';
EXEC createNotice @description = 'Road construction notice', @date = '2024-06-07', @propertyID = 7, @title = 'Construction Notice';
EXEC createNotice @description = 'Utility maintenance', @date = '2024-06-08', @propertyID = 8, @title = 'Utility Notice';
EXEC createNotice @description = 'Noise ordinance reminder', @date = '2024-06-09', @propertyID = 9, @title = 'Noise Reminder';
EXEC createNotice @description = 'Fire safety inspection', @date = '2024-06-10', @propertyID = 10, @title = 'Fire Safety Inspection';

-- Insert 10 applications
EXEC insertApplication @tenantID = 1, @description = 'Renew lease', @status = 'COMPLETED', @title = 'Lease Renewal';
EXEC insertApplication @tenantID = 2, @description = 'Maintenance request', @status = 'IN PROGRESS', @title = 'Maintenance Request';
EXEC insertApplication @tenantID = 3, @description = 'Pet approval request', @status = 'RECEIVED', @title = 'Pet Approval';
EXEC insertApplication @tenantID = 4, @description = 'Parking space reservation', @status = 'COMPLETED', @title = 'Parking Reservation';
EXEC insertApplication @tenantID = 5, @description = 'Tenant association membership', @status = 'IN PROGRESS', @title = 'Membership Application';
EXEC insertApplication @tenantID = 6, @description = 'Key replacement request', @status = 'RECEIVED', @title = 'Key Replacement';
EXEC insertApplication @tenantID = 7, @description = 'Complaint resolution', @status = 'COMPLETED', @title = 'Complaint Resolution';
EXEC insertApplication @tenantID = 8, @description = 'Amenity booking request', @status = 'IN PROGRESS', @title = 'Amenity Booking';
EXEC insertApplication @tenantID = 9, @description = 'Guest registration', @status = 'RECEIVED', @title = 'Guest Registration';
EXEC insertApplication @tenantID = 10, @description = 'Sublease approval request', @status = 'COMPLETED', @title = 'Sublease Approval';

-- Insert 10 Rents
EXEC rentProperty @tenantID = 1, @propertyID = 1, @rentAmount = 1200.00, @duration = 12, @startDate = '2024-01-01';
EXEC rentProperty @tenantID = 2, @propertyID = 2, @rentAmount = 1500.00, @duration = 6, @startDate = '2024-02-01';
EXEC rentProperty @tenantID = 3, @propertyID = 3, @rentAmount = 1000.00, @duration = 9, @startDate = '2024-03-01';
EXEC rentProperty @tenantID = 4, @propertyID = 4, @rentAmount = 1800.00, @duration = 12, @startDate = '2024-04-01';
EXEC rentProperty @tenantID = 5, @propertyID = 5, @rentAmount = 1300.00, @duration = 6, @startDate = '2024-05-01';
EXEC rentProperty @tenantID = 6, @propertyID = 6, @rentAmount = 1400.00, @duration = 12, @startDate = '2024-06-01';
EXEC rentProperty @tenantID = 7, @propertyID = 7, @rentAmount = 1600.00, @duration = 9, @startDate = '2024-07-01';
EXEC rentProperty @tenantID = 8, @propertyID = 8, @rentAmount = 1100.00, @duration = 6, @startDate = '2024-08-01';
EXEC rentProperty @tenantID = 9, @propertyID = 9, @rentAmount = 1700.00, @duration = 12, @startDate = '2024-09-01';
EXEC rentProperty @tenantID = 10, @propertyID = 10, @rentAmount = 1250.00, @duration = 6, @startDate = '2024-10-01';



