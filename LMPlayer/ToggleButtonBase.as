// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import flash.events.*;
	import SimpleButtonBase;


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
	public class ToggleButtonBase extends SimpleButtonBase
	{
		/** ON/OFFの状態(ONをtrueとする) */
		protected var onOffState: Boolean = false;

		/** On状態になったときに実行される関数 */
		protected var onFunction:Function;
		/** onFunction に渡されるデータ */
		protected var onData:Object;
		/** Off状態になったときに実行される関数 */
		protected var offFunction:Function;
		/** offFunction に渡されるデータ */
		protected var offData:Object;
		
		/**
		 * On状態になったときに実行される関数を設定する.
		 * 
		 * @param	fnc	起動する関数
		 * @param	obj	関数に渡すパラメータ
		 */
		public function setOnFunc(fnc: Function, obj:Object):void
		{
			onFunction = fnc;
			onData = obj;
		}

		/**
		 * Off状態になったときに実行される関数を設定する.
		 * 
		 * @param	fnc	起動する関数
		 * @param	obj	関数に渡すパラメータ
		 */
		public function setOffFunc(fnc: Function, obj:Object):void
		{
			offFunction = fnc;
			offData = obj;
		}

		/**
		 * ボタンをOn状態にする.
		 * 
		 * @param	noaction	trueに設定すると、 setOnFunc() で設定した関数を実行しない。
		 */
		public function setOn(noaction:Boolean=false):void
		{
			onOffState = true;
			this.gotoAndStop(onLabel);
			saveFrameNo = this.currentFrame;
			if ((onFunction != null) && (!noaction)) {
				onFunction(onData);
			}
		}

		/**
		 * ボタンをOff状態にする.
		 * 
		 * @param	noaction	trueに設定すると、 setOffFunc() で設定した関数を実行しない。
		 */
		public function setOff(noaction:Boolean=false):void
		{
			onOffState = false;
			this.gotoAndStop(offLabel);
			saveFrameNo = this.currentFrame;
			if ((offFunction != null) && (!noaction)) {
				offFunction(offData);
			}
		}

		/**
		 * ボタンのOn/Offの状態を返す。
		 * 
		 * @return	true: On / false: Off
		 */
		public function isOn(): Boolean
		{
			return onOffState;
		}

		/**
		 * クリックイベントリスナー.
		 * 
		 * <p>ボタンのOn/Offを反転する。</p>
		 * 
		 * @param	event	イベントオブジェクト
		 */
		override protected function clickHandler(event:MouseEvent):void
		{
			if (onOffState) {
				setOff();
			} else {
				setOn();
			}
		}

		/**
		 * コンストラクタ.
		 */
		public function ToggleButtonBase()
		{
			onOffState = false;
			this.gotoAndStop(offLabel);
			saveFrameNo = this.currentFrame;
		}
	}
}