//
//  EmployeeModel.swift
//  DatabaseHandler
//
//  Created by iT Gurus Software on 09/11/17.
//  Copyright © 2017 vaibhav. All rights reserved.
//

import Foundation

struct Employee
{
    let empName: String
    let empId: String
    let empSalary: String
    let empDesignation : String
    
    init?(empDictionary : [String:Any])
    {
        guard let name = empDictionary["emp_name"] as? String else { return nil}
        guard let id = empDictionary["emp_id"] as? String else { return nil}
        guard let salary = empDictionary["salary"] as? String else { return nil}
        guard let designation = empDictionary["designation"] as? String else { return nil}
        empName = name
        empId = id
        empSalary = salary
        empDesignation = designation
    }
}
