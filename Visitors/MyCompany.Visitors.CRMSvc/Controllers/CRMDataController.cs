using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Threading;

namespace MyCompany.Visitors.CRMSvc.Controllers
{
    [Produces("application/json")]
    [Route("api/CRMData")]
    public class CRMDataController : Controller
    {
        // GET: api/CRMData
        [HttpGet]
        public IEnumerable<string> Get()
        {
            return new string[] { };
        }

        // GET: api/CRMData/5
        [HttpGet("{id}", Name = "Get")]
        public async Task<IActionResult> GetAsync(int id)
        {
            CRMData returndata;

            try
            {
                
                returndata = await GetCRMDataAsync(id);
            }
            catch (Exception ex)
            {
                return NotFound(ex);
            }

            return new JsonResult(returndata);

        }

        // POST: api/CRMData
        [HttpPost]
        public void Post([FromBody]string value)
        {
        }

        // PUT: api/CRMData/5
        [HttpPut("{id}")]
        public void Put(int id, [FromBody]string value)
        {
        }

        // DELETE: api/ApiWithActions/5
        [HttpDelete("{id}")]
        public void Delete(int id)
        {
        }

        private async static Task<CRMData> GetCRMDataAsync(int id)
        {
            Random leads = new Random();

            if (id > 100)
            {
                throw new Exception($"Entity {id} not found in the CRM database");
            }

            if (id == 81)
            {
                Thread.Sleep(1000);
            }

            CRMData returndata = new CRMData()
            {
                VisitorId = id,
                CRMAccountManager = GetEmployeeName(),
                CRMLeads = leads.Next(0, 5)
            };

            return returndata;
        }

        private static string GetEmployeeName()
        {
            Random employee = new Random();

            return _employeeNames[employee.Next(0, 4)];
        }

        public class CRMData
        {
            public int VisitorId { get; set; }
            public int CRMLeads { get; set; }
            public string CRMAccountManager { get; set; }
        }

        private static List<string> _employeeNames = new List<string>()
        {
            "Winston Ochs",
            "Julia Fernandez",
            "Natasha Guthrie",
            "Ronnie Bayne",
            "Emily Marrow"
        };
    }
}
