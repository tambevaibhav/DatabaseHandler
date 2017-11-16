//
//  DatabaseHandlerClass.swift
//  SecondSwiftDemo
//
//  Created by Vaibhav on 9/1/15.
//  Copyright (c) 2015 Vaibhav. All rights reserved.
//

import UIKit

enum FieldType : String
{
    case Text = "TEXT"
    case Numeric = "INTEGER"
    case Blob = "BLOB"
    case IntegerPrimary = "INTEGER PRIMERY KEY"
}

enum ErrorType : Error
{
    case FileExistError
    case FileNotFoundError
    case CopyDatabaseError
    case CreateDatabaseError
    case CreatTabelError
    case InsertError
    case UpdateError
    case DeleteError
    case ReadError
    case DatabaseOpenError
}


struct Column
{
    var columnName : String
    var columnType : FieldType
}


struct ColumnValue
{
    var columnName : String
    var columnType : FieldType
    var columnValue : Any
}


class DatabaseHandlerClass: NSObject
{
    static let sharedInstance = DatabaseHandlerClass()
    
    let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
    
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private var databaseName : NSString = "employee.db"
    
    private var database: OpaquePointer? = nil
    
    private let dbDateFormatter = DateFormatter()
    
// MARK: - Class Initialization
    override init()
    {
        
    }
    
    init(databaseName : NSString) throws
    {
        super.init()
        self.databaseName = databaseName
        
        do
        {
         try createDatabaseIfNeeded()
        }
        catch
        {
            
        }
    }
    
    //this function returns database path with fix name.
    private func getDBPath() -> NSString
    {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        return paths.appendingPathComponent(self.databaseName as String) as NSString
    }

  
// MARK: - Database Initialization
    
    // Create a  copy of database from bundle if database is not present at path
    private func createDatabaseIfNeeded() throws -> Void
    {
        let dbPath: String = getDBPath() as String
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: dbPath) {
            guard let fromPath : String = Bundle.main.path(forResource: self.databaseName as String?, ofType: "db") else { throw ErrorType.FileNotFoundError }
            do {
                // Check Database file in bundle
               if( fileManager.fileExists(atPath: fromPath))
               {
                 try fileManager.copyItem(atPath: fromPath, toPath: dbPath)
                }
                else
               {
                // If databse file not present in bundle , create new file at document directory path
                if sqlite3_open(self.getDBPath().utf8String, &self.database) == SQLITE_OK
                {
                    print("Database Created Successfully")
                }
                else
                {
                    throw ErrorType.CreateDatabaseError
                }
                }
            } catch let error1 as NSError {
                 print(error1.description)
                throw error1
            }
        }
        else
        {
            throw ErrorType.FileExistError
        }
    }
  

    func createDatabaseWith(databaseName : NSString) throws
    {
        self.databaseName  = databaseName
        let dbPath: String = getDBPath() as String
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: dbPath)
        {
                // create Database file
                if  sqlite3_open(self.getDBPath().utf8String, &self.database) == SQLITE_OK
                {
                    print("Database Created Successfully")
                }
                else
                {
                    throw ErrorType.CreateDatabaseError
                }
            }
        else
        {
            throw ErrorType.FileExistError
        }
    }
        
    func copyDatabaseFromBundleWith(databaseName : NSString) throws
    {
        self.databaseName  = databaseName

        let dbPath: String = getDBPath() as String
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: dbPath)
        {
           guard let fromPath : String = Bundle.main.path(forResource: self.databaseName as String?, ofType: "") else
           {throw ErrorType.FileNotFoundError}
           
            do {
                // Check Database file in bundle
                if( fileManager.fileExists(atPath: fromPath))
                {
                    try fileManager.copyItem(atPath: fromPath, toPath: dbPath)
                }
                else
                {
                    throw ErrorType.CopyDatabaseError
                }
            } catch let error1 as NSError
            {
                print(error1.description)
                throw error1
            }
        }
        else
        {
            print("Database exist")
        }
    }

    
// MARK: - Create Table Operation
    
    
    func createTableWith(tableName : String , columnArray : Column...) -> Bool
    {
        
        var createQuery = "create table " + tableName + "("
        for (index,column) in columnArray.enumerated()
        {
            if index == (columnArray.count - 1)
            {
                createQuery += "\(column.columnName) \(column.columnType.rawValue)" + ")"
            }
            else
            {
                createQuery += "\(column.columnName) \(column.columnType.rawValue),"
            }
        }
      return  Execute(QueryStr: createQuery as NSString)
    }


    
// MARK: Insert Operation Methods
    func insertDataInto(tableName : String , columnArray : ColumnValue...) -> Bool
    {
       
        var createQuery = "INSERT INTO " + tableName + "("
        for (index,column) in columnArray.enumerated()
        {
            if index == (columnArray.count - 1)
            {
                createQuery += "\(column.columnName)" + ") VALUES ("
                for preapreIndex in 1...columnArray.count
                {
                    if preapreIndex == columnArray.count
                    {
                        createQuery += "?)"
                    }
                    else
                    {
                        createQuery += "?,"
                    }
                }
            }
            else
            {
                createQuery += "\(column.columnName),"
            }
        }
       
        var stmt:OpaquePointer? = nil

        if self.database == nil
        {
            if sqlite3_open(self.getDBPath().utf8String, &self.database) == SQLITE_OK
            {
            }
        }
                let result = sqlite3_prepare_v2(self.database, createQuery.cString(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue)), -1, &stmt, nil)
                if result != SQLITE_OK {
                    sqlite3_finalize(stmt)
                    if let error = String(validatingUTF8:sqlite3_errmsg(self.database)) {
                        let msg = "SQLiteDB - failed to prepare SQL: \(createQuery), Error: \(error)"
                        NSLog(msg)
                    }
                }
                
                
                var flag:CInt = 0
                
                
                let cntParams = sqlite3_bind_parameter_count(stmt)
                let cnt = CInt(columnArray.count)
                if cntParams != cnt {
                    let msg = "SQLiteDB - failed to bind parameters, counts did not match. SQL: \(createQuery), Parameters: \(columnArray)"
                    NSLog(msg)
                    return false
                }
                
                for index in 1...cnt {
                    
                    let columnType = columnArray[Int(index - 1)].columnType as FieldType
                    switch columnType
                    {
                    case .Text:
                        flag = sqlite3_bind_text(stmt, CInt(index), columnArray[Int(index - 1)].columnValue as? String, -1, SQLITE_TRANSIENT)
                        break;
                    case .Blob:
                        let data = columnArray[Int(index - 1)].columnValue as? NSData
                        flag = sqlite3_bind_blob(stmt, CInt(index), data?.bytes, CInt((data?.length)!), SQLITE_TRANSIENT)
                        break;
                    case .Numeric:
                        flag = sqlite3_bind_int(stmt, CInt(index), CInt((columnArray[Int(index - 1)].columnValue as? Int)!))
                        break;
                        
                    default:
                        break;
                    }
                    
                    // Check for errors
                    if flag != SQLITE_OK {
                        sqlite3_finalize(stmt)
                        if let error = String(validatingUTF8:sqlite3_errmsg(self.database)) {
                            let msg = "SQLiteDB - failed to bind for SQL: \(createQuery), Parameters: \(columnArray), Index: \(index) Error: \(error)"
                            NSLog(msg)
                        }
                        return false
                    }
                    
                    
                    return Execute(QueryStr: createQuery as NSString)
                }

        
    
        
        return false
}
    
    
// MARK: Database Operation Methods
    
    func Execute(QueryStr : NSString) -> Bool
    {
        let lockQueue =  DispatchQueue(label: "LockQueue")
       return lockQueue.sync
        { () -> Bool in
            
            if self.database == nil
            {
                if sqlite3_open(self.getDBPath().utf8String, &self.database) == SQLITE_OK
                {
                }
            }
                    QueryStr.replacingOccurrences(of: "null", with: "")
                    var cStatement:OpaquePointer? = nil
                    let executeSql = QueryStr as NSString
                    var lastId : Int?
                    let sqlStatement = executeSql.cString(using: String.Encoding.utf8.rawValue)
                    sqlite3_prepare_v2(self.database, sqlStatement, -1, &cStatement, nil)
                    let execute = sqlite3_step(cStatement)
                    print("\(execute)")
                    if execute == SQLITE_DONE
                    {
                        lastId = Int(sqlite3_last_insert_rowid(self.database))
                        print("Last Id :- \(lastId ?? 0)")
                        sqlite3_finalize(cStatement)
                        return true
                    }
                    else
                    {
                        print("Error in Run Statement :- \(sqlite3_errmsg16(self.database))")
                        sqlite3_finalize(cStatement)
                        return false
                    }
            
            }
    }
    
    
    func prepare(sql : NSString) -> OpaquePointer?
    {
        var cStatement:OpaquePointer? = nil
        sqlite3_open(self.getDBPath() as String, &self.database)
        let utfSql = sql.utf8String
        if sqlite3_prepare(self.database, utfSql, -1, &cStatement, nil) == 0
        {
            sqlite3_close(self.database)
            return cStatement!
        }
        else
        {
            sqlite3_close(self.database)
            return nil
        }
    }
    
    
    func dataBaseReader(query: NSString) throws -> Array<Any>?
    {
        var myDB_Array : [Any]?
    
    let lockQueue =  DispatchQueue(label: "LockQueue")
      try lockQueue.sync
    {
        
        var queryStatement: OpaquePointer? = nil
        
        
        if(self.database == nil) // Check Database is already opened
        {
            //If Database is not open previously then open it by following statement
           if (!(sqlite3_open(self.getDBPath() as String, &self.database) == SQLITE_OK))
           {
                throw ErrorType.DatabaseOpenError
            }
        }
        
        // Excute read query
        if sqlite3_prepare_v2(self.database, query.utf8String, -1, &queryStatement, nil) == SQLITE_OK
        {
            myDB_Array = [Any]()
           while sqlite3_step(queryStatement) == SQLITE_ROW
           {
            
            let tempDic = NSMutableDictionary()
            
            let columnCount = sqlite3_column_count(queryStatement) // Get column count

            for index in 0..<columnCount
            {
                let name = sqlite3_column_name(queryStatement, index) //Get column name
                
                if(name != nil)
                {
                    if let ptr = UnsafeRawPointer.init(sqlite3_column_text(queryStatement, index))
                    {
                        let uptr = ptr.bindMemory(to:CChar.self, capacity:0)
                        let txt = String(validatingUTF8:uptr) // Get value of coulmn
                        tempDic.setValue(txt, forKey: String(validatingUTF8 : name!)! ) // Add key value to Dictionary
                    }
                }
            }
            
            myDB_Array?.append(tempDic)// Add record dictionary to array
        }
            sqlite3_finalize(queryStatement)
        }else
        {
            sqlite3_finalize(queryStatement)
            throw ErrorType.ReadError
        }
        }
        
        return myDB_Array

}



// MARK: Date Methods
    func dbDate(dt:Date) -> String {
            return dbDateFormatter.string(from: dt)
    }

    func dbDateFromString(str:String, format:String="") -> Date? {
            let dtFormat = dbDateFormatter.dateFormat
            if !format.isEmpty {
                    dbDateFormatter.dateFormat = format
            }
                let dt = dbDateFormatter.date(from:str)
            if !format.isEmpty {
                    dbDateFormatter.dateFormat = dtFormat
            }
    return dt
}

}
