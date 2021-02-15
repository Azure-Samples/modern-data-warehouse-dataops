using Microsoft.Azure.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Models;
using Moq;
using Newtonsoft.Json;
using System;
using System.Text;
using System.Threading.Tasks;

namespace TemperatureEventsProj.Test
{

    [TestClass]
    public class DeviceIdFilterTest
    {
        private Mock<IAsyncCollector<DeviceEvent>> filteredDevicesEvh = new Mock<IAsyncCollector<DeviceEvent>>();
        private Mock<ILogger> log = new Mock<ILogger>();

        [TestMethod]
        public async Task TestTestFilteredDevicesId()
        {
            var deviceEvent = new DeviceEvent(999, default);

            convertEventData(deviceEvent);

            await Run(deviceEvent);

            filteredDevicesEvh.Verify(o => o.AddAsync(It.Is<DeviceEvent>(o => o.DeviceId == 999), default), Times.Once());
        }

        [TestMethod]
        public async Task TestTestNonFilteredDevicesId()
        {
            var deviceEvent = new DeviceEvent(1000, default);

            convertEventData(deviceEvent);

            await Run(deviceEvent);

            filteredDevicesEvh.Verify(o => o.AddAsync(It.IsAny<DeviceEvent>(), default), Times.Never());
        }

        private async Task Run(DeviceEvent payload)
        {
            await DeviceIdFilter.Run(new[] { convertEventData(payload) }, filteredDevicesEvh.Object, log.Object);
        }

        private EventData convertEventData(DeviceEvent payload)
        {
            return new EventData(new ArraySegment<byte>(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(payload))));
        }
    }
}
