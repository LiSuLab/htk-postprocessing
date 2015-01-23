using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CepstralExtraction {

	internal class Program {

		public static bool Silent;

		public static string InputFilename;
		public static string OutputFilename;
		public static List<CepstralCoefficientId> RequestedCepstralCoefficientIds = new List<CepstralCoefficientId>();

		private const string WordNamePattern = @"^-+ Source- (?<wordName>[a-z]+)\.wav -+$";

		private const string FrameVectorPattern = @"^(?<frameId>[0-9]+): "
												+ @"(?<C01>-?[0-9]+\.[0-9]+) "
												+ @"(?<C02>-?[0-9]+\.[0-9]+) "
												+ @"(?<C03>-?[0-9]+\.[0-9]+) "
												+ @"(?<C04>-?[0-9]+\.[0-9]+) "
												+ @"(?<C05>-?[0-9]+\.[0-9]+) "
												+ @"(?<C06>-?[0-9]+\.[0-9]+) "
												+ @"(?<C07>-?[0-9]+\.[0-9]+) "
												+ @"(?<C08>-?[0-9]+\.[0-9]+) "
												+ @"(?<C08>-?[0-9]+\.[0-9]+) "
												+ @"(?<C10>-?[0-9]+\.[0-9]+) "
												+ @"(?<C11>-?[0-9]+\.[0-9]+) "
												+ @"(?<C12>-?[0-9]+\.[0-9]+) "
												+ @"(?<C00>-?[0-9]+\.[0-9]+) "
												+ @"(?<D01>-?[0-9]+\.[0-9]+) "
												+ @"(?<D02>-?[0-9]+\.[0-9]+) "
												+ @"(?<D03>-?[0-9]+\.[0-9]+) "
												+ @"(?<D04>-?[0-9]+\.[0-9]+) "
												+ @"(?<D05>-?[0-9]+\.[0-9]+) "
												+ @"(?<D06>-?[0-9]+\.[0-9]+) "
												+ @"(?<D07>-?[0-9]+\.[0-9]+) "
												+ @"(?<D08>-?[0-9]+\.[0-9]+) "
												+ @"(?<D08>-?[0-9]+\.[0-9]+) "
												+ @"(?<D10>-?[0-9]+\.[0-9]+) "
												+ @"(?<D11>-?[0-9]+\.[0-9]+) "
												+ @"(?<D12>-?[0-9]+\.[0-9]+) "
												+ @"(?<D00>-?[0-9]+\.[0-9]+) "
												+ @"(?<A01>-?[0-9]+\.[0-9]+) "
												+ @"(?<A02>-?[0-9]+\.[0-9]+) "
												+ @"(?<A03>-?[0-9]+\.[0-9]+) "
												+ @"(?<A04>-?[0-9]+\.[0-9]+) "
												+ @"(?<A05>-?[0-9]+\.[0-9]+) "
												+ @"(?<A06>-?[0-9]+\.[0-9]+) "
												+ @"(?<A07>-?[0-9]+\.[0-9]+) "
												+ @"(?<A08>-?[0-9]+\.[0-9]+) "
												+ @"(?<A08>-?[0-9]+\.[0-9]+) "
												+ @"(?<A10>-?[0-9]+\.[0-9]+) "
												+ @"(?<A11>-?[0-9]+\.[0-9]+) "
												+ @"(?<A12>-?[0-9]+\.[0-9]+) "
												+ @"(?<A00>-?[0-9]+\.[0-9]+)$";

		public static void Main(string[] args) {

			// set up the static state
			ParseArgs(args);

			using (FileStream fsIn = new FileStream(InputFilename, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
			using (FileStream fsOut = new FileStream(OutputFilename, FileMode.Create, FileAccess.Write, FileShare.ReadWrite))
			using (StreamReader sr = new StreamReader(fsIn, Encoding.UTF8))
			using (StreamWriter sw = new StreamWriter(fsOut, Encoding.UTF8)) {

				// Start reading lines from the input file
				string readLine;
				while ((readLine = sr.ReadLine()) != null) {

					if (Regex.IsMatch(readLine, WordNamePattern)) {
						// Matched a new word name
						// Write that word name in the output file
						string wordName = Regex.Match(readLine, WordNamePattern).Groups["wordName"].Value;
						sw.WriteLine(wordName);
						if(!Silent) Console.WriteLine(wordName);
					}
					else if (Regex.IsMatch(readLine, FrameVectorPattern)) {
						// Matched a frame vector pattern

						Match m = Regex.Match(readLine, FrameVectorPattern);
						
						// get out requested coefficients
						List<string> matchedCoefficients = RequestedCepstralCoefficientIds.Select(requestedId => m.Groups[requestedId.MatchValue].Value).ToList();

						// Write frame id and requested coefficients to the line
						sw.WriteLine(string.Format("{0},{1}", m.Groups["frameId"].Value, String.Join(",", matchedCoefficients)));
					}

				}

			}
		}

		/// <summary>
		/// Parses the args given to the program, and sets up static state accordingly.
		/// </summary>
		/// <param name="args"></param>
		private static void ParseArgs(string[] args) {
			// Switches begin with -
			List<string> switches = args.Where(arg => !String.IsNullOrEmpty(arg) && arg.First() == '-').ToList();
			// parameters don't begin with - and contain a = which separates the command into a key and a value
			Dictionary<string, string> parameters = (
				from arg in args
				where !String.IsNullOrEmpty(arg) && arg.First() != '-' && arg.Contains('=')
				let parts = arg.Split('=').Take(2)
					// remove whitespace and ignore empty bits
					.Select(part => part.Trim()).Where(part => part != "").ToList()
				// want key=value, not key= or =value
				where parts.Count == 2
				select new KeyValuePair<string, string>(parts[0], parts[1])).ToList()
				.ToDictionary(kvp => kvp.Key, kvp => kvp.Value);
			// commands don't begin with - and don't contain =
			List<string> commands =
				args.Where(arg => !String.IsNullOrEmpty(arg) && arg.First() != '-' && !arg.Contains("=")).ToList();

			#region switches
			Silent = switches.Contains("S");
			#endregion

			#region commands
			if (parameters.ContainsKey("input")) {
				InputFilename = parameters["input"];
			}
			else throw new ArgumentException("input");

			if (parameters.ContainsKey("output")) {
				OutputFilename = parameters["output"];
			}
			else throw new ArgumentException("output");

			if (parameters.ContainsKey("C")) {
				RequestedCepstralCoefficientIds.AddRange(ParseListParameter(parameters, "C").Select(order => new CepstralCoefficientId(CCType.C, order)));
			}

			if (parameters.ContainsKey("D")) {
				RequestedCepstralCoefficientIds.AddRange(ParseListParameter(parameters, "D").Select(order => new CepstralCoefficientId(CCType.D, order)));
			}

			if (parameters.ContainsKey("A")) {
				RequestedCepstralCoefficientIds.AddRange(ParseListParameter(parameters, "A").Select(order => new CepstralCoefficientId(CCType.A, order)));
			}
			#endregion
		}

		/// <summary>
		/// Parse a parameter as a list
		/// </summary>
		/// <param name="parameters"></param>
		/// <param name="key"></param>
		/// <returns></returns>
		private static IEnumerable<int> ParseListParameter(IReadOnlyDictionary<string, string> parameters, string key) {
			if (key == null) throw new ArgumentNullException("key");
			return parameters[key].Split(',').Select(ParseAsInt);
		}

		/// <summary>
		/// Parse a string as an int
		/// </summary>
		/// <param name="input"></param>
		/// <returns></returns>
		// todo: this should be unnecessary
		private static int ParseAsInt(string input) {
			int attempt;
			int.TryParse(input, out attempt);
			return attempt;
		}

	}

	/// <summary>
	/// Represents info about a word.
	/// Immutable.
	/// </summary>
	internal class WordInfo {

		public readonly string Word;
		public readonly Dictionary<int,Dictionary<CepstralCoefficientId, float>> CepstralCoefficients;

		public WordInfo(string word) {
			if (word == null) throw new ArgumentNullException("word");

			Word = word;
			CepstralCoefficients = new Dictionary<int, Dictionary<CepstralCoefficientId, float>>();
		}

	}

	/// <summary>
	/// Represents a particular cepstral coefficient
	/// </summary>
	internal class CepstralCoefficientId : IEquatable<CepstralCoefficientId> {

		//public static List<CepstralCoefficientId> 

		public readonly CCType Type;
		public readonly int Order;

		public CepstralCoefficientId(CCType type, int order) {
			// only allowed 0-12
			if (!(new[] {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}).Contains(order)) throw new NotImplementedException();
			Type = type;
			Order = order;
		}

		public string MatchValue {
			get { return Type.Name + Order.ToString("00"); }
		}


		#region IEquatable
		public bool Equals(CepstralCoefficientId other) {
			return other.Type == Type && other.Order == Order;
		}
		#endregion
	}

	/// <summary>
	/// Represents the type of a cepstral coefficient.
	/// Immutable.
	/// </summary>
	public class CCType : IEquatable<CCType> {

		public static readonly CCType C = new CCType("C");
		public static readonly CCType D = new CCType("D");
		public static readonly CCType A = new CCType("A");

		public readonly string Name;

		private CCType(string name) {
			Name = name;
		}

		#region IEquatable

		public bool Equals(CCType other) {
			return other.Name == Name;
		}
		#endregion
	}

}
