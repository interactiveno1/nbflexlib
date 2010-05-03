package com.nbilyk.utils {
	import flash.utils.ByteArray;
	

	public class ByteArrayUtils {
		
		/**
		 *  Modified from Adobe's HistoryManagerImpl. 
		 * 
		 *  Function to calculate a cyclic rendundancy checksum (CRC).
		 *  This returns a 4-character hex string representing a 16-bit uint
		 *  calculated from the specified string using the CRC-CCITT mask.
		 *  In http://www.joegeluso.com/software/articles/ccitt.htm,
		 *  the following sample input and output is given to check
		 *  this implementation:
		 *  "" -> "1D0F"
		 *  "A" -> "9479"
		 *  "123456789" -> "E5CC"
		 *  "AA...A" (256 A's) ->"E938"
		 */
		public static function calcCrc(b:ByteArray):String {
			var oldPosition:uint = b.position;
			b.position = 0;
			var crc:uint = 0xFFFF;

			// Process each character in the string.
			var n:int = b.length;
			for (var i:int = 0; i < n; i++) {
				var byte:uint = b.readByte();

				// Unicode characters can be greater than 255.
				// If so, we let both bytes contribute to the CRC.
				// If not, we let only the low byte contribute.
				var loByte:uint = byte & 0x00FF;
				var hiByte:uint = byte >> 8;
				if (hiByte != 0) crc = updateCrc(crc, hiByte);
				crc = updateCrc(crc, loByte);
			}

			// Process 2 additional zero bytes, as specified by the CCITT algorithm.
			crc = updateCrc(crc, 0);
			crc = updateCrc(crc, 0);
			b.position = oldPosition;

			return crc.toString(16);
		}
		private static function updateCrc(crc:uint, byte:uint):uint {
			const poly:uint = 0x1021; // CRC-CCITT mask

			var bitMask:uint = 0x80;

			// Process each bit in the byte.
			for (var i:int = 0; i < 8; i++) {
				var xorFlag:Boolean = (crc & 0x8000) != 0;

				crc <<= 1;
				crc &= 0xFFFF;

				if ((byte & bitMask) != 0)
					crc++;

				if (xorFlag)
					crc ^= poly;

				bitMask >>= 1;
			}

			return crc;
		}

	}
}