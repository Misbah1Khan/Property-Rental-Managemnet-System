using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using RentalManagemnet.Models;

namespace RentalManagemnet.Controllers
{
    
    public class HomeController : Controller
    {
        private readonly string adminUsername = "admin";
        private readonly string adminPassword = "admin123";
        Models.RentalManagementEntities rental = new Models.RentalManagementEntities();
        public ActionResult Index()
        {
            var incomeList = rental.retrieveIncome().ToList();
            var expenseList = rental.retrieveExpense().ToList();

            ViewBag.Expense = expenseList;
            ViewBag.Income = incomeList;
            int occupiedCount = rental.Properties.Count(p => p.tenantID != null);

            // Total count of properties
            int totalCount = rental.Properties.Count();

            // Count of unoccupied properties
            int unoccupiedCount = totalCount - occupiedCount;

            // Calculate occupancy ratios
            decimal occupiedRatio = (decimal)occupiedCount / totalCount * 100;
            decimal unoccupiedRatio = (decimal)unoccupiedCount / totalCount * 100;

            // Pass data to view
            ViewBag.OccupiedRatio = occupiedRatio;
            ViewBag.UnoccupiedRatio = unoccupiedRatio;

            var result = rental.Database.SqlQuery<ViewModel.RentSummaryViewModel>(@"
    SELECT 
        SUM(CASE WHEN invoiceStatus = 'PAID' AND invoiceType = 'RENT' THEN amountDue ELSE 0 END) AS RentReceived,
        SUM(CASE WHEN invoiceStatus = 'UNPAID' AND invoiceType = 'RENT' THEN amountDue ELSE 0 END) AS RentOverdue
    FROM 
        Invoice
").FirstOrDefault();

            decimal totalRent = result.RentReceived + result.RentOverdue;
            decimal rentReceivedPercentage = totalRent == 0 ? 0 : (result.RentReceived / totalRent) * 100;
            decimal rentOverduePercentage = totalRent == 0 ? 0 : (result.RentOverdue / totalRent) * 100;

            ViewBag.RentReceived = Math.Round(result.RentReceived, 2);
            ViewBag.RentOverdue = Math.Round(result.RentOverdue, 2);
            ViewBag.RentReceivedPercentage = Math.Round(rentReceivedPercentage, 2);
            ViewBag.RentOverduePercentage = Math.Round(rentOverduePercentage, 2);

            var notices = rental.Notices
                                  .OrderByDescending(n => n.noticeDate)
                                  .Take(3)
                                  .Select(n => new ViewModel.NoticeViewModel
                                  {
                                      NoticeID = n.noticeID,
                                      NoticeDescription = n.noticeDescription,
                                      NoticeDate = n.noticeDate ?? DateTime.MinValue
                                  })
                                  .ToList();

            ViewBag.Notices = notices;
            return View();
        }


        public ActionResult Tenants()
        {
            ViewBag.Message = "Your application description page.";
            var Tenants = rental.Tenants.ToList();
            return View(Tenants);
        }

        public ActionResult EditTenant(int id)
        {
            var tenant = rental.Tenants.Where(x => x.tenantID == id).FirstOrDefault();
            return View(tenant);
        }
        [HttpPost]
        public ActionResult EditTenant(Tenant t)
        {
            var tenant = rental.Tenants.Where(x => x.tenantID == t.tenantID).FirstOrDefault();
            tenant.tenantName = t.tenantName;
            tenant.tenantPhone = t.tenantPhone;
            tenant.CNIC = t.CNIC;
            tenant.agentID = t.agentID;
            rental.SaveChanges();
            TempData["Message"] = "<script>alert('Data edited successfully')</script>";
            return RedirectToAction("Tenants");
        }

        public ActionResult DeleteTenant(int id)
        {
            var tenant = rental.Tenants.FirstOrDefault(x => x.tenantID == id);
            if (tenant == null)
            {
                return HttpNotFound();
            }
            return View(tenant);
        }

        // POST: Home/DeleteTenant/5
        [HttpPost, ActionName("DeleteTenant")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteTenantConfirmed(int id)
        {
            var tenant = rental.Tenants.FirstOrDefault(x => x.tenantID == id);
            if (tenant != null)
            {
                rental.deleteTenant(id);
                rental.SaveChanges();
            }
            return RedirectToAction("Tenants");
        }

        public ActionResult CreateTenant()
        {
            return View();
        }
        [HttpPost]
        public ActionResult CreateTenant(Tenant p)
        {
            //@agentID int, @name varchar(255),@phone varchar(255),@cnic varchar(255),@propertyID int
            try
            {
                rental.createTenant(p.agentID, p.tenantName, p.tenantPhone, p.CNIC);
                rental.SaveChanges();
                return RedirectToAction("Tenants");
            }
            catch (Exception ex)
            {

            }
            return View();
        }

        public ActionResult Properties()
        {
            ViewBag.Message = "Your application description page.";
            ViewBag.Rented = rental.retrieveRentedProperties().ToList();
            ViewBag.Sold = rental.retrieveSoldProperties().ToList();
            ViewBag.Empty = rental.retrieveEmptyProperties().ToList();
            return View();
        }

        public ActionResult EditProperty(int id)
        {
            var property = rental.Properties.Where(x => x.propertyID == id).FirstOrDefault();
            return View(property);
        }
        [HttpPost]
        public ActionResult EditProperty(Property t)
        {
            var property = rental.Properties.Where(x => x.propertyID == t.propertyID).FirstOrDefault();
            property.propertyAddress = t.propertyAddress;
            property.propertyType = t.propertyType;
            property.propertyRooms = t.propertyRooms;
            property.propertyGarages = t.propertyGarages;
            property.status = t.status;
            rental.SaveChanges();
            TempData["Message"] = "<script>alert('Data edited successfully')</script>";
            return RedirectToAction("Properties");
        }
        public ActionResult DeleteProperty(int id)
        {
            var property = rental.Properties.FirstOrDefault(x => x.propertyID == id);
            if (property == null)
            {
                return HttpNotFound();
            }
            return View(property);
        }

        // POST: Home/DeleteTenant/5
        [HttpPost, ActionName("DeleteProperty")]
        [ValidateAntiForgeryToken]
        public ActionResult DeletePropertyConfirmed(int id)
        {
            var property = rental.Properties.FirstOrDefault(x => x.propertyID == id);
            if (property != null)
            {
                property.status = "SOLD";
                property.tenantID = null;
                rental.SaveChanges();
            }
            return RedirectToAction("Properties");
        }

        public ActionResult CreateProperty()
        {
            return View();
        }
        [HttpPost]
        public ActionResult CreateProperty(Property p)
        {
            //@agentID int, @name varchar(255),@phone varchar(255),@cnic varchar(255),@propertyID int
            try
            {
                rental.createProperty(p.propertyAddress, p.propertyType, int.Parse(p.propertyRooms), p.propertyGarages);
                rental.SaveChanges();
                return RedirectToAction("Properties");
            }
            catch (Exception ex)
            {

            }
            return View();
        }

        public ActionResult Maintenance()
        {
            ViewBag.Message = "Your application description page.";
            var Maintenance = rental.Maintenances.ToList();
            return View(Maintenance);
        }

        public ActionResult CreateMaintenance()
        {
            return View();
        }
        [HttpPost]
        public ActionResult CreateMaintenance(Maintenance p)
        {
            //@description varchar(255),@cost money,@date date,@propertyID int,@title varchar(255
            try
            {
                rental.insertMaintenance(p.maintenanceDescription, p.maintenanceCost, p.maintenanceDate, p.propertyID, p.maintenanceTitle);
                rental.SaveChanges();
                return RedirectToAction("Maintenance");
            }
            catch (Exception ex)
            {

            }
            return View();
        }
        public ActionResult Notifications()
        {
            ViewBag.Message = "Your contact page.";
            var Notifications = rental.Notices.ToList();
            return View(Notifications);
        }

        public ActionResult CreateNotice()
        {
            return View();
        }
        [HttpPost]
        public ActionResult CreateNotice(Notice p)
        {
            //@description varchar(255),@date date, @propertyID int,@title varchar(255)
            try
            {
                rental.createNotice(p.noticeDescription, p.noticeDate, p.propertyID, p.noticeTitle);
                rental.SaveChanges();
                return RedirectToAction("Notifications");
            }
            catch (Exception ex)
            {

            }
            return View();
        }
        public ActionResult EditNotice(int id)
        {
            var notice = rental.Notices.Where(x => x.noticeID == id).FirstOrDefault();
            return View(notice);
        }
        [HttpPost]
        public ActionResult EditNotice(Notice t)
        {
            var notice = rental.Notices.Where(x => x.noticeID == t.noticeID).FirstOrDefault();
            notice.noticeTitle = t.noticeTitle;
            notice.noticeDescription = t.noticeDescription;
            notice.noticeDate = t.noticeDate;
            notice.propertyID = t.propertyID;
            rental.SaveChanges();
            TempData["Message"] = "<script>alert('Data edited successfully')</script>";
            return RedirectToAction("Notifications");
        }
        public ActionResult DeleteNotice(int id)
        {
            var notice = rental.Notices.FirstOrDefault(x => x.noticeID == id);
            if (notice == null)
            {
                return HttpNotFound();
            }
            return View(notice);
        }
        [HttpPost, ActionName("DeleteNotice")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteNoticeConfirmed(int id)
        {
            var notice = rental.Notices.FirstOrDefault(x => x.noticeID == id);
            if (notice != null)
            {
                rental.Notices.Remove(notice);
                rental.SaveChanges();
            }
            return RedirectToAction("Notifications");
        }
        public ActionResult Invoices()
        {
            ViewBag.Message = "Your application description page.";
            var Invoice = rental.Invoices.ToList();
            return View(Invoice);
        }

        public ActionResult CreateInvoice()
        {

            List<SelectListItem> InvoiceTypeOptions = new List<SelectListItem>
         {
     new SelectListItem { Value = "WATER", Text = "WATER" },
     new SelectListItem { Value = "GAS", Text = "GAS" },
     new SelectListItem { Value = "ELECTRICITY", Text = "ELECTRICITY" },
     new SelectListItem { Value = "RENT", Text = "RENT" }
     };
            ViewBag.InvoiceTypeOptions = InvoiceTypeOptions;
            return View();
        }
        [HttpPost]
        public ActionResult CreateInvoice(Invoice p)
        {
            ViewBag.InvoiceTypeOptions = new List<SelectListItem>
     {
          new SelectListItem { Value = "WATER", Text = "WATER" },
          new SelectListItem { Value = "GAS", Text = "GAS" },
          new SelectListItem { Value = "ELECTRICITY", Text = "ELECTRICITY" },
          new SelectListItem { Value = "RENT", Text = "RENT" }
      };
            //@propertyID int, @dueDate date, @amount money, @type varchar(255)
            try
            {
                rental.createInvoice(p.propertyID, p.dueDate, p.amountDue, p.invoiceType);
                rental.SaveChanges();
                return RedirectToAction("Invoices");
            }
            catch (Exception ex)
            {

            }
            return View();
        }

        public ActionResult Agents()
        {
            ViewBag.Message = "Your application description page.";
            var Agents = rental.Agents.ToList();
            return View(Agents);
        }

        public ActionResult CreateAgent()
        {
            return View();
        }
        [HttpPost]
        public ActionResult CreateAgent(Agent p)
        {
            //@name varchar(255),@phone varchar(255),@address varchar(255),@fees money
            try
            {
                rental.insertAgent(p.agentName, p.agentPhone, p.agentAddress, p.agentFees);
                rental.SaveChanges();
                return RedirectToAction("Agents");
            }
            catch (Exception ex)
            {

            }
            return View();
        }

        public ActionResult DeleteAgent(int id)
        {
            var agent = rental.Agents.FirstOrDefault(x => x.agentID == id);
            if (agent == null)
            {
                return HttpNotFound();
            }
            return View(agent);
        }
        [HttpPost, ActionName("DeleteAgent")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteAgentConfirmed(int id)
        {
            var agent = rental.Agents.FirstOrDefault(x => x.agentID == id);
            if (agent != null)
            {
                rental.deleteAgent(agent.agentID);
                rental.SaveChanges();
            }
            return RedirectToAction("Agents");
        }

        public ActionResult EditAgent(int id)
        {
            var agent = rental.Agents.Where(x => x.agentID == id).FirstOrDefault();
            return View(agent);
        }
        [HttpPost]
        public ActionResult EditAgent(Agent t)
        {
            //@name varchar(255),@phone varchar(255),@address varchar(255),@fees money
            var agent = rental.Agents.Where(x => x.agentID == t.agentID).FirstOrDefault();
            agent.agentName = t.agentName;
            agent.agentPhone = t.agentPhone;
            agent.agentAddress = t.agentAddress;
            agent.agentFees = t.agentFees;
            rental.SaveChanges();
            TempData["Message"] = "<script>alert('Data edited successfully')</script>";
            return RedirectToAction("Agents");
        }
        public ActionResult Transactions()
        {
            ViewBag.Message = "Your application description page.";
            var Transactions = rental.Transactions.ToList();
            return View(Transactions);
        }



        public ActionResult Applications()
        {
            ViewBag.Message = "Your application description page.";
            var Applications = rental.Applications.ToList();
            return View(Applications);
        }

        public ActionResult EditApplication(int id)
        {
            var application = rental.Applications.Where(x => x.applicationID == id).FirstOrDefault();
            List<SelectListItem> ApplicationStatus = new List<SelectListItem>
         {
     new SelectListItem { Value = "IN PROGRESS", Text = "IN PROGRESS" },
     new SelectListItem { Value = "RECEIVED", Text = "RECEIVED" },
     new SelectListItem { Value = "COMPLETED", Text = "COMPLETED" }
     };
            ViewBag.ApplicationStatus = ApplicationStatus;
            return View(application);
        }
        [HttpPost]
        public ActionResult EditApplication(Models.Application t)
        {
            ViewBag.ApplicationStatus = new List<SelectListItem>
     {
           new SelectListItem { Value = "IN PROGRESS", Text = "IN PROGRESS" },
     new SelectListItem { Value = "RECEIVED", Text = "RECEIVED" },
     new SelectListItem { Value = "COMPLETED", Text = "COMPLETED" }
      };
            //@name varchar(255),@phone varchar(255),@address varchar(255),@fees money
            var application = rental.Applications.Where(x => x.applicationID == t.applicationID).FirstOrDefault();
            application.applicationStatus = t.applicationStatus;
            rental.SaveChanges();
            TempData["Message"] = "<script>alert('Data edited successfully')</script>";
            return RedirectToAction("Applications");
        }

        public ActionResult Rents()
        {
            ViewBag.Message = "Your application description page.";
            var Rents = rental.Rents.ToList();
            return View(Rents);
        }

        public ActionResult EditRent(int id)
        {
            var rent = rental.Rents.Where(x => x.rentID == id).FirstOrDefault();
            return View(rent);
        }
        [HttpPost]
        public ActionResult EditRent(Rent t)
        {
            //@name varchar(255),@phone varchar(255),@address varchar(255),@fees money
            var rent = rental.Rents.Where(x => x.rentID == t.rentID).FirstOrDefault();
            rent.RentAmount = t.RentAmount;
            rent.startDate = t.startDate;
            rent.endDate = t.endDate;
            rental.SaveChanges();
            TempData["Message"] = "<script>alert('Data edited successfully')</script>";
            return RedirectToAction("Rents");
        }

        public ActionResult DeleteRent(int id)
        {
            var rent = rental.Rents.FirstOrDefault(x => x.rentID == id);
            if (rent == null)
            {
                return HttpNotFound();
            }
            return View(rent);
        }
        [HttpPost, ActionName("DeleteRent")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteRentConfirmed(int id)
        {
            var rent = rental.Rents.FirstOrDefault(x => x.rentID == id);
            if (rent != null)
            {
                rental.deleteRent(rent.rentID);
                rental.SaveChanges();
            }
            return RedirectToAction("Rents");
        }

        public ActionResult CreateRent()
        {
            return View();
        }
        [HttpPost]
        public ActionResult CreateRent(Rent p)
        {
            //@tenantID int ,@propertyID int, @rentAmount money, @duration int,@startDate date
            try
            {
                rental.rentProperty(p.tenantID, p.propertyID, p.RentAmount, p.Duration, p.startDate);
                rental.SaveChanges();
                return RedirectToAction("Rents");
            }
            catch (Exception ex)
            {

            }
            return View();
        }

        public ActionResult Login()
        { 
         return View();
        }

        [HttpPost]
        public ActionResult AdminLogin(string username, string password)
        {
            if (username == adminUsername && password == adminPassword)
            {
                // Redirect to the admin index page
                return RedirectToAction("Index", "Home");
            }
            else
            {
                // Return to login view with an error message
                ViewBag.ErrorMessage = "Invalid admin credentials.";
                return RedirectToAction("Login", "Home");
            }
        }

        public ActionResult Logout()
        {
            return RedirectToAction("Login", "Home");
        }

    }
}