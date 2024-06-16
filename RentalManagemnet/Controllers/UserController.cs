using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace RentalManagemnet.Controllers
{
    public class UserController : Controller
    {
        Models.RentalManagementEntities rental = new Models.RentalManagementEntities();
        // GET: User
        public ActionResult Index()
        {

            int tenantID = Convert.ToInt32(Session["tenantID"]);
            var tenant = rental.Tenants.FirstOrDefault(x => x.tenantID == tenantID);
            var properties = rental.retrievePropertiesOfUser(tenantID).ToList();
            ViewBag.propertyCount = properties.Count;
            var unpaidlist = rental.retrieveUnpaidInvoicesOfUser(tenantID).ToList();
            ViewBag.unpaidcount = unpaidlist.Count;
            return View(tenant);
        }

        public ActionResult Applications()
        {
            int tenantID = Convert.ToInt32(Session["tenantID"]);
            ViewBag.Applicationss = rental.retrieveApplicationsOfUser(tenantID).ToList();
            return View();
        }

        public ActionResult CreateApplication()
        {
            return View();
        }
        [HttpPost]
        public ActionResult CreateApplication(Models.Application p)
        {
            //@tenantID int, @description varchar(255),@status varchar(255),@title varchar(255)
            try
            {
                int tenantID = Convert.ToInt32(Session["tenantID"]);
                rental.insertApplication(tenantID, p.applicationDescription, "RECEIVED", p.applicationTitle);
                rental.SaveChanges();
                return RedirectToAction("Applications");
            }
            catch (Exception ex)
            {

            }
            return View();
        }
        public ActionResult DeleteApplication(int id)
        {
            var application = rental.Applications.FirstOrDefault(x => x.applicationID == id);
            if (application == null)
            {
                return HttpNotFound();
            }
            return View(application);
        }
        [HttpPost, ActionName("DeleteApplication")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteApplicationConfirmed(int id)
        {
            var application = rental.Applications.FirstOrDefault(x => x.applicationID == id);
            if (application != null)
            {
                rental.Applications.Remove(application);
                rental.SaveChanges();
            }
            return RedirectToAction("Applications");
        }
        public ActionResult Invoices()
        {
            int tenantID = Convert.ToInt32(Session["tenantID"]);
            ViewBag.Paid = rental.retrievePaidInvoicesOfUser(tenantID).ToList();
            ViewBag.Unpaid = rental.retrieveUnpaidInvoicesOfUser(tenantID).ToList();
            return View();
        }
        public ActionResult Notifications()
        {
            var Notifications = rental.Notices.ToList();
            return View(Notifications);
        }
        public ActionResult Properties()
        {
            var tenantID = Session["tenantID"];
            ViewBag.properties = rental.retrievePropertiesOfUser(Convert.ToInt32(tenantID)).ToList();
            return View();
        }
        [HttpPost]
        public ActionResult UserLogin(string username, string password)
        {
            if (validCredentials(username, password))
            {
                int tenantID = int.Parse(username);
                Session["tenantID"] = tenantID;
                return RedirectToAction("Index", "User");
            }
            return RedirectToAction("Login", "Home");
        }

        public bool validCredentials(string username, string password)
        {
            int tenantID = int.Parse(username);
            int passwordd = int.Parse(password);
            var tenant = rental.Tenants.FirstOrDefault(t => t.tenantID == tenantID && t.password == passwordd);

            // If a matching tenant is found, return true. Otherwise, return false.
            return tenant != null;
        }

        public ActionResult Logout()
        {
            Session.Clear();
            return RedirectToAction("Login", "Home");
        }

        public ActionResult PayInvoice(int id)
        {
            var invoice = rental.Invoices.FirstOrDefault(i => i.invoiceID == id);
            if (invoice == null)
            {
                return HttpNotFound();
            }
            rental.insertTransaction(id, invoice.amountDue);
            return RedirectToAction("Invoices", "User");
        }

    }
}