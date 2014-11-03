/*
 * This is a language binding for the ev3dev device APIs. More info at: https://github.com/ev3dev/ev3dev-lang
 * This library complies with spec v0.9.1
 */

using GLib;

namespace ev3dev
{
	public errordomain DeviceError
	{
		NOT_CONNECTED,
		IO_ERROR
	}

	public class Device : GLib.Object
	{
		public string device_root { get; protected set; }
		public bool connected { get; protected set; }
	
		private string connect_error = "You must connect to a device before you can read from it.";
		private string read_error = "There was an error reading from the file";
		private string write_error = "There was an error writing to the file";

		public Device()
		{
		
		}

		public void connect(string device_root_path)
		{
			this.device_root = device_root_path;
			this.connected = true;
		}

		private string construct_property_path(string property)
		{
			return GLib.Path.build_filename(this.device_root, property);
		}

		public int read_int(string property) throws DeviceError
		{
			string str_value = this.read_string(property);

			int result;
			result = int.parse(str_value);

			return result;
		}

		public string read_string(string property) throws DeviceError
		{
			if(!this.connected)
				throw new DeviceError.NOT_CONNECTED(this.connect_error);

			string result;
			try
			{
				var file = File.new_for_path(this.construct_property_path(property));
				var input_stream = new DataInputStream(file.read());
				result = input_stream.read_line();
			}
			catch (Error error)
			{
				this.connected = false;
				throw new DeviceError.IO_ERROR(this.read_error + ": " + error.message);
			}

			return result;
		}

		/* Note: All write methods have a limit of 256 bytes to increase write speed */

		public void write_int(string property, int value) throws DeviceError
		{
			this.write_string(property, value.to_string());
		}

		public void write_string(string property, string value) throws DeviceError
		{
			if(!this.connected)
				throw new DeviceError.NOT_CONNECTED(this.connect_error);

			try
			{
				string property_path = this.construct_property_path(property);
				var file = File.new_for_path(property_path);
				var read_write_stream = file.open_readwrite();
				var out_stream = new DataOutputStream(new BufferedOutputStream.sized(read_write_stream.output_stream, 256));
				out_stream.put_string(value);
				out_stream.flush();
			}
			catch (Error error)
			{
				this.connected = false;
				throw new DeviceError.IO_ERROR(this.write_error + ": " + error.message);
			}
		}
	}

	public const string INPUT_AUTO = null;
	public const string OUTPUT_AUTO = null;
	
	public const string INPUT_1 = "in1";
	public const string INPUT_2 = "in2";
	public const string INPUT_3 = "in3";
	public const string INPUT_4 = "in4";

	public const string OUTPUT_A = "outA";
	public const string OUTPUT_B = "outB";
	public const string OUTPUT_C = "outC";
	public const string OUTPUT_D = "outD";

	public class Motor : Device
	{
		private string port;
		private const string motor_device_dir = "/sys/class/tacho-motor";
		private int device_index { get; private set; default = -1; }

		public Motor (string port = null, string? type = null)
		{
			this.port = port;
			string root_path = "";

			try
			{
				var directory = File.new_for_path(this.motor_device_dir);
				var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);

				FileInfo device_file;
				while((device_file = enumerator.next_file()) != null)
				{
					if(device_file.get_file_type() == FileType.DIRECTORY)
						continue;

					string device_file_name = device_file.get_name();

					root_path = Path.build_path("/", this.motor_device_dir, device_file_name);
					
					string port_name;
					string motor_type;
					
					{ //We don't need a bunch of IO streams and such floating around
						var port_name_file = File.new_for_path(Path.build_path("/", root_path, "port_name"));
						var port_input_stream = new DataInputStream(port_name_file.read());
						port_name = port_input_stream.read_line();
						
						var type_file = File.new_for_path(Path.build_path("/", root_path, "type"));
						var type_input_stream = new DataInputStream(type_file.read());
						motor_type = type_input_stream.read_line();
					}

					bool satisfies_condition = (
						(port == OUTPUT_AUTO)
						|| (port_name == (port))
					) && (
						(type == null || type == "")
						|| motor_type == type
					);

					if(satisfies_condition)
					{
						this.device_index = int.parse(device_file_name.substring("motor".length));
						break;
					}
				}

				if(this.device_index == -1)
				{
					this.connected = false;
					return;
				}
			}
			catch
			{
				this.connected = false;
				return;
			}

			this.connect(root_path);
		}

		public void reset()
		{
			this.write_int("reset", 1);
		}

		//PROPERTIES
		public string port_name
		{
			owned get
			{
				return this.read_string("port_name");
			}
		}

		public int duty_cycle
		{
			get
			{
				return this.read_int("duty_cycle");
			}
		}

		public int duty_cycle_sp
		{
			get
			{
				return this.read_int("duty_cycle_sp");
			}

			set
			{
				this.write_int("duty_cycle_sp", value);
			}
		}
		
		public int position
		{
			get
			{
				return this.read_int("position");
			}

			set
			{
				this.write_int("position", value);
			}
		}
		
		public string position_mode
		{
			owned get
			{
				return this.read_string("position_mode");
			}
			
			set
			{
				this.write_string("position_mode", value);
			}
		}
		
		public int position_sp
		{
			get
			{
				return this.read_int("position_sp");
			}

			set
			{
				this.write_int("position_sp", value);
			}
		}
		
		public int pulses_per_second
		{
			get
			{
				return this.read_int("pulses_per_second");
			}
		}
		
		public int pulses_per_second_sp
		{
			get
			{
				return this.read_int("pulses_per_second_sp");
			}
			
			set
			{
				this.write_int("pulses_per_second_sp", value);
			}
		}
		
		public int ramp_down_sp
		{
			get
			{
				return this.read_int("ramp_down_sp");
			}

			set
			{
				this.write_int("ramp_down_sp", value);
			}
		}
		
		public int ramp_up_sp
		{
			get
			{
				return this.read_int("ramp_up_sp");
			}

			set
			{
				this.write_int("ramp_up_sp", value);
			}
		}
		
		public string regulation_mode
		{
			owned get
			{
				return this.read_string("regulation_mode");
			}
			
			set
			{
				this.write_string("regulation_mode", value);
			}
		}
		
		public int run
		{
			get
			{
				return this.read_int("run");
			}

			set
			{
				this.write_int("run", value);
			}
		}

		public string run_mode
		{
			owned get
			{
				return this.read_string("run_mode");
			}
			
			set
			{
				this.write_string("run_mode", value);
			}
		}
		
		public int speed_regulation_P
		{
			get
			{
				return this.read_int("speed_regulation_P");
			}

			set
			{
				this.write_int("speed_regulation_P", value);
			}
		}
		
		public int speed_regulation_I
		{
			get
			{
				return this.read_int("speed_regulation_I");
			}

			set
			{
				this.write_int("speed_regulation_I", value);
			}
		}
		
		public int speed_regulation_D
		{
			get
			{
				return this.read_int("speed_regulation_D");
			}

			set
			{
				this.write_int("speed_regulation_D", value);
			}
		}
		
		public int speed_regulation_K
		{
			get
			{
				return this.read_int("speed_regulation_K");
			}

			set
			{
				this.write_int("speed_regulation_K", value);
			}
		}
		
		public string state
		{
			owned get
			{
				return this.read_string("state");
			}
		}
		
		public string stop_mode
		{
			owned get
			{
				return this.read_string("stop_mode");
			}
			
			set
			{
				this.write_string("stop_mode", value);
			}
		}
		
		public string[] stop_modes
		{
			owned get
			{
				return this.read_string("stop_modes").split(" ");
			}
		}
		
		public int time_sp
		{
			get
			{
				return this.read_int("time_sp");
			}

			set
			{
				this.write_int("time_sp", value);
			}
		}
		
		public string motor_type //"type" is a reserved property name in Vala
		{
			owned get
			{
				return this.read_string("type");
			}
		}
	}
	
	public class Sensor : Device
	{
		private string port;
		private const string sensor_device_dir = "/sys/class/msensor";
		private int device_index { get; private set; default = -1; }

		public Sensor (string port = null, string[]? types = null, string? i2c_address = null)
		{
			this.port = port;
			string root_path = "";

			try
			{
				var directory = File.new_for_path(this.sensor_device_dir);
				var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);
				
				FileInfo device_file;
				while((device_file = enumerator.next_file()) != null)
				{
					if(device_file.get_file_type() == FileType.DIRECTORY)
						continue;

					string device_file_name = device_file.get_name();

					root_path = Path.build_path("/", this.sensor_device_dir, device_file_name);
					
					string port_name;
					string type_name;
					string i2c_device_address;
					
					{ //We don't need a bunch of IO streams and such floating around
						var port_name_file = File.new_for_path(Path.build_path("/", root_path, "port_name"));
						var port_input_stream = new DataInputStream(port_name_file.read());
						port_name = port_input_stream.read_line();
						
						var type_file = File.new_for_path(Path.build_path("/", root_path, "name"));
						var type_input_stream = new DataInputStream(type_file.read());
						type_name = type_input_stream.read_line();
						
						var i2c_file = File.new_for_path(Path.build_path("/", root_path, "address"));
						var i2c_input_stream = new DataInputStream(i2c_file.read());
						i2c_device_address = i2c_input_stream.read_line();
					}
					
					bool satisfies_condition = (
						(port == INPUT_AUTO)
						|| (port_name == port)
					) && (
						(types == null || types.length < 1)
						|| type_name in types
					) && (
						i2c_address == null
						|| i2c_address == i2c_device_address
					);

					if(satisfies_condition)
					{
						this.device_index = int.parse(device_file_name.substring("sensor".length));
						break;
					}
				}

				if(this.device_index == -1)
				{
					this.connected = false;
					return;
				}
			}
			catch
			{
				this.connected = false;
				return;
			}

			this.connect(root_path);
		}
		
		public int get_value(int value_index)
		{
			return this.read_int("value" + value_index.to_string());
		}
		
		public float get_float_value(int value_index)
		{
			double decimal_factor = Math.pow((double)10, (double)this.read_int("dp"));
			return (float) ((double)this.read_int("value" + value_index.to_string()) / decimal_factor);
		}

		//PROPERTIES
		public string port_name
		{
			owned get
			{
				return this.read_string("port_name");
			}
		}

		public int num_values
		{
			get
			{
				return this.read_int("num_values");
			}
		}

		public string type_name
		{
			owned get
			{
				return this.read_string("name");
			}
		}
		
		public string mode
		{
			owned get
			{
				return this.read_string("mode");
			}
			
			set
			{
				this.write_string("mode", value);
			}
		}
		
		public string[] modes
		{
			owned get
			{
				return this.read_string("modes").split(" ");
			}
		}
	}
	
	public class I2CSensor : Sensor
	{
		public I2CSensor (string port, string[]? types, string? i2c_address)
		{
			base(port, types, i2c_address);
		}
		
		public int poll_ms
		{
			get
			{
				return this.read_int("poll_ms");
			}

			set
			{
				this.write_int("poll_ms", value);
			}
		}
		
		public string fw_version
		{
			owned get
			{
				return this.read_string("fw_version");
			}
		}
	}
	
	public class PowerSupply : Device
	{
		private string power_device_dir = "/sys/class/power_supply/";
		public string device_name = "legoev3-battery";
		
		public PowerSupply (string? device_name)
		{
			if(device_name != null)
				this.device_name = device_name;
			
			try
			{
				var directory = File.new_for_path(this.power_device_dir);
				var enumerator = directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);

				FileInfo device_file;
				while((device_file = enumerator.next_file()) != null)
				{
					if(device_file.get_file_type() == FileType.DIRECTORY)
						continue;

					string device_file_name = device_file.get_name();
					if(device_file_name == this.device_name)
					{
						this.connect(Path.build_path("/", this.power_device_dir, device_file_name));
						return;
					}
				}
			}
			catch
			{ }
			
			this.connected = false;
		}
		
		public int current_now
		{
			get
			{
				return this.read_int("current_now");
			}
		}
		
		public int voltage_now
		{
			get
			{
				return this.read_int("voltage_now");
			}
		}
		
		public int voltage_max_design
		{
			get
			{
				return this.read_int("voltage_max_design");
			}
		}
		
		public int voltage_min_design
		{
			get
			{
				return this.read_int("voltage_min_design");
			}
		}
		
		public string technology
		{
			owned get
			{
				return this.read_string("technology");
			}
		}
		
		//Variable name "type" not allowed
		public string device_type
		{
			owned get
			{
				return this.read_string("type");
			}
		}
		
		public double voltage_volts
		{
			get
			{
				return this.voltage_now / 1000000;
			}
		}
		
		public double current_amps
		{
			get
			{
				return current_now / 1000000;
			}
		}
	}
}