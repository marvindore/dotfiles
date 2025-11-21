```tsql
DECLARE @result INT

EXEC @result = sp_getapplock 
    @Resource = 'MyResource2', 
    @LockMode = 'Exclusive', 
    @LockOwner = 'Session', 
    @LockTimeout = 1000; -- Wait for 1 second

SELECT [@result]=@result

IF @result >= 0
BEGIN
    -- Lock acquired successfully
    SELECT [ ]='Lock acquired';
    --BEGIN TRANSACTION
    -- Perform operations that require the lock here
    UPDATE dbo.Company SET CmpAddressLine2='blah SUITE 301 blah' WHERE CmpCoID = 'RYVMD'
    --COMMIT TRAN
END 
ELSE
BEGIN
    -- Failed to acquire lock
    SELECT [ ]='Failed to acquire lock';
END

-- Release the lock
DECLARE @result int
EXEC @result = sp_releaseapplock 
    @Resource = 'MyResource2', 
    @LockOwner = 'Session'
SELECT @result
Fim:

```
