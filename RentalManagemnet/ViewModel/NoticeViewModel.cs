using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace RentalManagemnet.ViewModel
{
    public class NoticeViewModel
    {
        public int NoticeID { get; set; }
        public string NoticeDescription { get; set; }
        public DateTime NoticeDate { get; set; }
    }
}