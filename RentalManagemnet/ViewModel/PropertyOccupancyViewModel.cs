using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace RentalManagemnet.ViewModel
{
    public class PropertyOccupancyViewModel
    {
        public int OccupiedCount { get; set; }
        public int UnoccupiedCount { get; set; }
        public double OccupiedPercentage { get; set; }
        public double UnoccupiedPercentage
        {
            get; set;
        }
    }
}