namespace Models
{
    public class DeviceEvent
    {
        public DeviceEvent(int deviceId, int temperature)
        {
            DeviceId = deviceId;
            Temperature = temperature;
        }

        public int DeviceId { get; }
        public int Temperature { get; }
    }
}
