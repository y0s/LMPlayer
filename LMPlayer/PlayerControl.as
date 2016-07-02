// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import flash.events.*;
	import VolumeControl;
	import CustomSeekBarBase;
	import SimpleButtonBase;
	import ToggleButtonBase;
	import RadioButtonBase;

	/**
	 * プレーヤー操作パネルクラス
	 */
	public class PlayerControl extends MovieClip
	{
		/** 音量バー */
		public var mcVolumeControl:VolumeControl;
		
		/** 頭出しボタン */
		public var bHead:SimpleButtonBase;
		/** フレーム戻しボタン */
		public var bPrevF:SimpleButtonBase;
		/** 1秒戻しボタン */
		public var bPrevS:SimpleButtonBase;
		/** 全区間選択ボタン */
		public var bAllRange:SimpleButtonBase;
		/** 再生ボタン */
		public var bPlay:SimpleButtonBase;
		/** 一時停止ボタン */
		public var bPause:SimpleButtonBase;
		/** スロー再生ボタン */
		public var bSlow:ToggleButtonBase;
		/** 1秒送りボタン */
		public var bNextS:SimpleButtonBase;
		/** フレーム送りボタン */
		public var bNextF:SimpleButtonBase;
		
		/** 繰り返し再生On/Offボタン */
		public var bRepeatOnOff:ToggleButtonBase;

		/** フルスクリーン切り替えボタン */
		public var bFullScreen:SimpleButtonBase;
		
		/** シークバー */
		public var mc_seekBar:CustomSeekBarBase;
		
		/**
		 * コンストラクタ.
		 */
		public function PlayerControl()
		{
			bHead.buttonEnabled = false;
		}

	}
}