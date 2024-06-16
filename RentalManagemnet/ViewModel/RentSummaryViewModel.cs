using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace RentalManagemnet.ViewModel
{
    public class RentSummaryViewModel
    {
        public decimal RentReceived { get; set; }
        public decimal RentOverdue { get; set; }
    }
}