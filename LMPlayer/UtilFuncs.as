// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.system.*;
	import flash.net.LocalConnection;
	
	/**
	 * 汎用関数クラス
	 */
	public class UtilFuncs
	{
		
		/**
		 * 秒数に対応する時間・分・秒表記を取得.
		 * 
		 * @param	second		秒数
		 * @param	usemillisec	ミリ秒まで表記するかどうか(true: 表記する / false: 表記しない)
		 * @return	時間･分･秒表記の文字列
		 */
		public static function secondToHMS(second:Number, usemillisec:Boolean = false):String
		{
			var hour:int;
			var min:int;
			var strsec:String;
			
			hour = int(second / 3600);
			second -= hour * 3600;
			
			min = int(second / 60);
			second -= min * 60;
			
			strsec = (second < 10)?("0" + second):String(second);
			if (!usemillisec) {
				// 整数表記の場合
				strsec = strsec.substr(0, 2);
			} else {
				// ミリ秒まで表記する場合
				if (strsec.length == 2) {
					// 小数点以下が無い場合、末尾に ".000" を付ける
					strsec += ".000";
				} else {
					// 小数点以下が3桁無い場合のために "000" を付けてから桁数を揃える
					strsec = (strsec + "000").substr(0, 6);
				}
			}
			return ((hour < 10) ? ("0" + hour) : String(hour)) + ":" + ((min < 10) ? ("0" + min):String(min)) + ":" + strsec;
		}
		
		/**
		 * 時間・分・秒表記から秒数を取得.
		 * 
		 * @param	hms		時間・分･秒表記
		 * @param	errorVal	エラー時の戻り値
		 * @return	秒数
		 */
		public static function HMSToSecond(hms:String, errorVal:Number = 0):Number
		{
			var hmsarr:Array = hms.split(":");
			if (hmsarr.length < 3) {
				return errorVal;
			} else {
				hmsarr[0] = int(hmsarr[0]);
				hmsarr[1] = int(hmsarr[1]);
				hmsarr[2] = Number (hmsarr[2]);
				if (isNaN(hmsarr[2])) {
					hmsarr[2] = 0;
				}
				return hmsarr[0] * 3600 + hmsarr[1] * 60 + hmsarr[2];
			}
		}

		/**
		 * 文字列→数値変換.
		 * 
		 * @param	str	文字列
		 * @return	変換した数値(変換失敗時は NaN ではなく 0 を返す)
		 */
		public static function StringToNumber(str:String):Number
		{
			var val:Number = Number(str);
			return isNaN(val) ? 0 : val;
		}
		
		/**
		 * Flashプレイヤーのバージョンチェック.
		 * 
		 * @return	true: ver.10.1以上 / false: ver.10.1未満
		 */
		public static function isFP10_1():Boolean
		{
			var va:Array = Capabilities.version.split(" ")[1].toString().split(","); 
			if(int(va[0]) > 10) { return true; } 
			if(int(va[0]) < 10) { return false; } 
			if(int(va[1]) > 1) { return true; } 
			if(int(va[1]) < 1) { return false; } 
			return true; 
		}
		
		/**
		 * URLチェック.
		 * 
		 * @param	URLstring	チェックする文字列
		 * @return	文字列が相対パスか、 "http://" か　"https://" で始まっていて同一ドメインならtrue
		 */
		public static function checkProtocol(URLstring:String):Boolean
		{
			//文字列が英数下線文字列とコロンで始まっていなければ相対パスと見なす。
			var patternAbs:RegExp = new RegExp("^\\w+:.*");
			if (patternAbs.exec(URLstring) == null) {
				return true;
			}
			//相対パスでなければ、"http://～/" か "https://～/" で同一ドメインのみOK
			var my_lc:LocalConnection = new LocalConnection();
			var domainName:String = my_lc.domain;
			var pattern:RegExp = new RegExp("^https?://([^/]+)/");
			var result:Object = pattern.exec(URLstring);
			if (result == null || result[1] != domainName || URLstring.length >= 4096) {
				return (false);
			}
			return (true);
		}
		
		/**
		 * 文字列・Boolean変換
		 * 
		 * @param	str					入力文字列
		 * @param	retvalForInvalid	変換できないときに返す値
		 * @return	変換したBoolean値
		 */
		public static function strToBoolean(str:String, retvalForInvalid:Boolean = true):Boolean
		{
			if (str == null) return false;
			switch(str.toLowerCase()) {
			case "yes":
			case "true":
			case "on":
			case "1":
				return true;
				break;
			case "no":
			case "false":
			case "off":
			case "0":
			case "":
				return false;
				break;
			default:
				return retvalForInvalid;
				break;
			}
		}
		
		/**
		 * コンストラクタ.
		 */
		public function UtilFuncs()
		{
		}
	}
}
