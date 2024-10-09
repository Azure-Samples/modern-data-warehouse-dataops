using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace TelemetryProcessor.Models.CustomAttributes
{
    /// <summary>
    /// Validate GuidFormat.
    /// </summary>
    public class GuidFormatAttribute : ValidationAttribute
    {
        private const string Pattern = @"(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}";

        /// <summary>
        /// Verify the input.
        /// </summary>
        /// <param name="value">input value.</param>
        /// <returns>bool.</returns>
        public override bool IsValid(object value)
        {
            if (value is null)
            {
                return true;
            }

            if (value is string)
            {
                Regex regex = new Regex(Pattern);
                Match match = regex.Match(value as string);
                if (match.Success)
                {
                    return true;
                }
            }

            return false;
        }
    }
}