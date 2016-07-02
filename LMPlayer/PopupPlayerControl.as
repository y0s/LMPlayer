// Copyright (c) 2013 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import flash.events.*;
	import VolumeControl;
	import CustomSeekBarBase;
	import SimpleButtonBase;

	/**
	 * プレーヤー操作パネルクラス
	 */
	public class PopupPlayerControl extends MovieClip
	{
		/** 音量バー */
		public var mcVolumeControl:VolumeControl;
		
		/** 再生ボタン */
		public var bPlay:SimpleButtonBase;
		/** 一時停止ボタン */
		public var bPause:SimpleButtonBase;
		
		/** シークバー */
		public var mc_seekBar:CustomSeekBarBase;
		
		/** 全画面表示解除ボタン */
		public var bNormalScreen:SimpleButtonBase;
		
		/** 操作パネルを隠す */
		public var bClose:SimpleButtonBase;

		/**
		 * コンストラクタ.
		 */
		public function PopupPlayerControl()
		{
		}

	}
}