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
    public class TemperatureFilterTest
    {
        private Mock<IAsyncCollector<DeviceEvent>> analyticsEvh = new Mock<IAsyncCollector<DeviceEvent>>();
        private Mock<IAsyncCollector<DeviceEvent>> outOfBoundsEvh = new Mock<IAsyncCollector<DeviceEvent>>();
        private Mock<ILogger> log = new Mock<ILogger>();

        [TestMethod]
        public async Task TestTemperatureWithInBounds()
        {
            var deviceEvent = new DeviceEvent(default, 99);

            convertEventData(deviceEvent);

            await Run(deviceEvent);

            analyticsEvh.Verify(o => o.AddAsync(It.Is<DeviceEvent>(o => o.Temperature == 99), default), Times.Once());
            outOfBoundsEvh.Verify(o => o.AddAsync(It.IsAny<DeviceEvent>(), default), Times.Never());
        }

        [TestMethod]
        public async Task TestTemperatureOutOfBounds()
        {
            var deviceEvent = new DeviceEvent(default, 100);

            convertEventData(deviceEvent);

            await Run(deviceEvent);

            analyticsEvh.Verify(o => o.AddAsync(It.IsAny<DeviceEvent>(), default), Times.Never());
            outOfBoundsEvh.Verify(o => o.AddAsync(It.Is<DeviceEvent>(o => o.Temperature == 100), default), Times.Once());
        }

        private async Task Run(DeviceEvent payload)
        {
            await TemperatureFilter.Run(new[] { convertEventData(payload) }, analyticsEvh.Object, outOfBoundsEvh.Object, log.Object);
        }

        private EventData convertEventData(DeviceEvent payload)
        {
            return new EventData(new ArraySegment<byte>(Encoding.UTF8.GetBytes(JsonConvert.SerializeObject(payload))));
        }
    }
}
