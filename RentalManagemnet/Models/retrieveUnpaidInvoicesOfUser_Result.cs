//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace RentalManagemnet.Models
{
    using System;
    
    public partial class retrieveUnpaidInvoicesOfUser_Result
    {
        public int invoiceID { get; set; }
        public Nullable<int> propertyID { get; set; }
        public Nullable<System.DateTime> issueDate { get; set; }
        public Nullable<System.DateTime> dueDate { get; set; }
        public Nullable<decimal> amountDue { get; set; }
        public string invoiceType { get; set; }
        public string invoiceStatus { get; set; }
    }
}
