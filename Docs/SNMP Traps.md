This note is for understanding SNMP traps in detail, as it is an old technology with not a lot of surviving documentation outside of RFCs. SNMP traps are used as the only way to monitor the Vault when a customer does not allow syslog.

# Breaking Down SNMP Traps
SNMP v2 Trap PDUs are in the following format:
- Sequence Tag + Sequence Length
	- SNMP Version (TLV)
		- Data type
		- Version length
		- Version
	- Community String (TLV)
		- Data type
		- Community String length
		- Community String
	- PDU Type
	- Varbind Message Length
	- Request Id (TLV)
	- Error-Status + Error-Index (TLV)
- Varbind definition (Sequence)
	- Varbinds (Sequence)
		- OID
		- Value

All SNMP PDUs are encoded using ASN.1 BER, this includes SNMP v2 Trap PDUs.
Many fields in the SNMP v2 Trap PDU consists of Type-Length-Value (TLV) encoded values. The type (sometimes called a tag) represents the type of data in the TLV block.
The types often found in SNMP v2 Trap PDUs include `0x02` (Integer), `0x04` (OctetString), `0x06` (ObjectIdentifier) and `0x30` (Sequence Tag).

![[Pasted image 20230412105908.png|400]]

The following logic is used to represent integer values (used in lengths):
- If the value is `0x7F` (127) or less, it will be a one-byte value (known as Short-Form variable length)
- If the value is `0x80` (128) or more, it will be split into multiple bytes (known as Long-Form variable length)
	- The first byte will be the length of the value in bytes, prefixed by `0x8`
	- Example: Sequence length 335 (0xDD) will be presented as: `0x81 0xDD`
	- Example: Sequence length 990 (0x3DE) will be presented as: `0x82 0x03 0xDE`
	- Example: Sequence length 1024 (0x400) will presented as: `0x82 0x04 0x00`
	- `0x82` can represent up to 8.585.215 decimal, so in most cases, you will only see `0x81` and `0x82`

The PDU can be split up into "sequences" encoded as TLV, each with a sequence tag (`0x30)`, sequence length and value fields. This can be thought of as "nested" sequences.
- The initial Sequence Tag denotes the entire PDU
- The Sequence Tag in the Varbinds sequence denotes all varbinds
- Each varbind has its own Sequence Tag

![[SNMP Trap PCAP ColorCoded.png]]


## Sequence Tag + Sequence Length
The initial Sequence Tag field denotes the entire SNMP v2 Trap PDU. Sequence Tags are always `0x30`.

The Sequence Length field denotes the length of the enture SNMP v2 Trap PDU.
For longer SNMP Traps, the value may exceed `0x80` and is then encoded as Long Form: `0x81 0xd4` shows that the rest of the PDU is `0xd4` (212 bits).

## SNMP Version
SNMP Version is calculated as a TLV value.
The first byte (data type) is always `0x02`, which is an Integer
The second byte (length) is always `0x01`, which indicates that the length of the version string is 1 byte.

The third byte is the SNMP Version value.
- SNMP v1: `0x00`
- SNMP v2c: `0x01`
- SNMP v3: `0x02`

## Community String
Community String is calculated as a TLV value.
The first byte (data type) is always `0x04`, which is an Octet String.
The second byte (length) is the total length of the community string including quotes, if used.
- "Public": `0x08`

After Community String length comes the community string itself as a char array.
- Public: `0x50 0x75 0x62 0x6c 0x69 0x63`

```powershell
# This is a simple example to turn a string into a char array
[Byte[]]$byteCommunity = [System.Text.Encoding]::ASCII.GetBytes("Public")
$byteCommunity
# Output: 50 75 62 6C 69 63
```


## PDU Type
The PDU Type field identifies the type of message being sent, prefixed with `0xa`.
- SNMP v1 Trap: `0xa4` (4)
- SNMP v2 Trap: `0xa7` (7)

![SNMP PDU Type falues](http://www.tcpipguide.com/free/aa2107c5.png)


## Varbind Message Length
The Varbind Message Length field indicates the length of the rest of the PDU, including error statuses, error indexes and varbinds.
For longer SNMP Traps, the value may exceed `0x80` and is then encoded as Long Form: `0x81 0xd4` shows that the rest of the PDU is `0xd4` (212 bits).

## Request Id
Request Id is calculated as a TLV value.
The first byte (data type) is always `0x02`, which is an Integer.
The second byte (length) is the length in bytes of the value (most often `0x01` or `0x02`)

After Integer Length comes the Request Id itself.

## Error-Status + Error-Index
Error-Status and Error-Index are calculated as TLV values.
The first byte (data type) is always `0x02`, which is an Integer.
The second byte (length) is the length in bytes of the value (most often `0x01` or `0x02`)

Error-Status will be `0x00` if the error status is "noError".
Error-Index will be `0x00` if the first varbind (`0x00`) generated the trap.

It is unknown when Error-Index will be anything other than `0x00`.

## Varbinds
The rest of the PDU is for varbinds. This field is calculated as a TLV value.
The Sequence Tag `0x30` is followed by the length of the sequence. The "sequence" in this case is the rest of the PDU.

Each varbind are calculated as individual TLV values.

### Sequence Tag
The sequence tag to start a varbind is always `0x30`.
In this case, the "sequence" is only the specific varbind.

### Sequence Length
The length of the rest of the varbind.

### Varbind OID and value
The OID and value.

Breaking down the example `.1.3.6.1.2.1.1.3.0` (hex `0x06 0x08 0x2b 0x06 0x01 0x02 0x01 0x01 x03 0x00`):
- `0x06`: Data type "ObjectIdentifier"
- `0x08`: Length of the OID in bytes
- `0x2b`: A shortening of `0x01 0x03` specified in the SNMP standard
- The rest of the sequence is each part of the OID

Breaking down the example sysUpTime value `1846100` (hex `0x43 0x03 0x1c 0x2b 0x54`)
- `0x43`: Data type "TimeTicks"
- `0x03`: Length of the value in bytes
- The rest of the sequence is the value

Breaking down a string value `Hello, world! :)` (hex `0x04 0x10 0x48 0x65 0x6c 0x6c 0x6f 0x2c 0x20 0x77 0x6f 0x72 0x6c 0x64 0x21 0x21 0x20 0x3a 0x29`)
- `0x04`: Data type "OctetString"
- `0x10`: Length of the value in bytes
- The rest of the sequence is the value


# Sending SNMP Traps in PowerShell with SharpSNMPLib
[Variable, Lextm.SharpSnmpLib C# (CSharp) Code Examples - HotExamples](https://csharp.hotexamples.com/examples/Lextm.SharpSnmpLib/Variable/-/php-variable-class-examples.html)
[TrapV2Message, Lextm.SharpSnmpLib.Messaging C# (CSharp) Code Examples - HotExamples](https://csharp.hotexamples.com/examples/Lextm.SharpSnmpLib.Messaging/TrapV2Message/-/php-trapv2message-class-examples.html)

SharpSNMPLib is a .NET Library shipped as a DLL that can perform most SNMP operations.
The bare minimum to send an SNMP Trap using SharpSNMPLib is as follows:
```powershell
    Param (
		[string]$DestinationIP = "192.168.1.1",
		[string]$Community = 'Public',
		[string[]]$ObjectIdentifier = '.1.3.6.1.2.1.1.2.0',
		[string]$TrapText
	)
    
    Add-Type -Path $PSScriptRoot/SharpSnmpLib.dll
	$ParsedIp = [System.Net.IPAddress]::Parse($DestinationIp)
	$TargetIPEndPoint = New-Object System.Net.IpEndPoint ($ParsedIp.GetAddressBytes(), 162)
	
	$DataPayload = New-Object System.Collections.Generic.List[Lextm.SharpSnmpLib.Variable]
	$OIDObject = [Lextm.SharpSnmpLib.ObjectIdentifier]::new($ObjectIdentifier)
	$OctetString = [Lextm.SharpSnmpLib.OctetString]::new($TrapText)
	$Variable = [Lextm.SharpSnmpLib.Variable]::new($ObjectIdentifier, $OctetString)
	$DataPayload.Add($Variable)
	
	$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
	$sysUpTime = [int]$uptime.TotalSeconds * 100
	$requestId = (Get-Random -Minimum 1000 -Maximum 3000)

	[Lextm.SharpSnmpLib.Messaging.Messenger]::SendTrapV2(
		$requestId, #requestid
		[Lextm.SharpSnmpLib.VersionCode]::"V2",
		$TargetIPEndPoint, #Target
		[Lextm.SharpSnmpLib.OctetString]::new($Community), #Community
		[Lextm.SharpSnmpLib.ObjectIdentifier]::new($ObjectIdentifier), #snmpTrapOID varbind
		$sysUpTime, #sysUpTime varbind
		$DataPayload #custom varbinds
	)
```




# Sending SNMP Traps using Net-SNMP snmptrap
`snmptrap` is a part of the Net-SNMP toolset commonly found on UNIX-like systems. Net-SNMP can be compiled on Windows too, and a pre-compiled mirror can be found at [net-snmp tools for windows (unofficial) (elifulkerson.com)](https://elifulkerson.com/articles/net-snmp-windows-binary-unofficial.php).

```
snmptrap.exe -m ALL -v 2c -c public 192.168.1.1 '' .1.3.6.1.4.1.8072.2.3.0.1 .1.3.6.1.4.1.8072.2.3.2.1 s "Test Trap"

-m ALL: Required to avoid MIB-related errors on Windows
-v 2c: Version
-c public: Community string "public"
192.168.1.1: trap receiver
'': timestamp
.1.3.6.1.4.1.8072.2.3.0.1: snmpTrapOID
.1.3.6.1.4.1.8072.2.3.2.1: custom varbind OID
s "Test Trap": custom varbind value (s for type String)
```



# Links and References
[Decode SNMP PDUs - Where to Start? - Stack Overflow](https://stackoverflow.com/questions/22998212/decode-snmp-pdus-where-to-start)
[The TCP/IP Guide - SNMP Version 2 (SNMPv2) Message Formats (tcpipguide.com)](http://www.tcpipguide.com/free/t_SNMPVersion2SNMPv2MessageFormats-5.htm)
[RFC 1905 - Protocol Operations for Version 2 of the Simple Network Management Protocol (SNMPv2) (ietf.org)](https://datatracker.ietf.org/doc/html/rfc1905)
[A Layman's Guide to a Subset of ASN.1, BER, and DER (ntop.org)](http://luca.ntop.org/Teaching/Appunti/asn1.html)
[ASN.1 Basic Encoding Rules (oss.com)](https://www.oss.com/asn1/resources/asn1-made-simple/asn1-quick-reference/basic-encoding-rules.html)
[ASN.1 Quick Reference (oss.com)](https://www.oss.com/asn1/resources/asn1-made-simple/asn1-quick-reference.html)
[ASN.1 DER and BER integer encodings](https://github.com/pre-srfi/variable-length/issues/1)
[A Warm Welcome to ASN.1 and DER - Let's Encrypt (letsencrypt.org)](https://letsencrypt.org/docs/a-warm-welcome-to-asn1-and-der/)
