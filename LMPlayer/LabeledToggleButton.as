// Copyright (c) 2013 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import ToggleButtonBase;

	/**
	 * トグルボタンクラス.
	 * 
	 * <p>クリックするとON/OFFが切り替わるボタン。</p>
	 * <p>ボタンとするMovieClipは、以下のフレームを持つ。</p>
	 * <ul>
	 * <li>フレーム "l_on" にOn状態のデザイン。</li>
	 * <li>フレーム "l_off" にOff状態のデザイン。</li>
	 * <li>フレーム "l_over" にマウスオーバー時のデザイン。</li>
	 * <li>hasDisableImage を true に設定した場合は、フレーム "l_disable" が機能無効時のデザインとして使われる。</li>
	 * </ul>
	 */
	public class LabeledToggleButton extends ToggleButtonBase
	{
		/** ボタンに表示するラベル */
		public var label:TextField;

		/**
		 * コンストラクタ.
		 */
		public function LabeledToggleButton()
		{
		}
	}
}