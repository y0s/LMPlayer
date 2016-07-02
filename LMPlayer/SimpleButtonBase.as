// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import flash.events.*;

	/**
	 * ボタンクラス.
	 * 
	 * <p>ボタンのベース。</p>
	 * <p>ボタンとするMovieClipは、以下のフレームを持つ。</p>
	 * <ul>
	 * <li>フレーム1に通常時のデザイン。</li>
	 * <li>フレーム "l_over" にマウスオーバー時のデザイン。(オプション)</li>
	 * <li>フレーム "l_down" にマウスダウン時のデザイン。(オプション)</li>
	 * <li><code>hasDisableImage</code> を true に設定した場合は、フレーム "l_disable" が機能無効時のデザインとして使われる。</li>
	 * </ul>
	 */
	public class SimpleButtonBase extends MovieClip
	{
		/**
		 * 機能無効時のビジュアルがあるかどうか. 
		 * 
		 * <p>true に設定すると、フレーム "l_disable" を機能無効時のデザインとして使用する。</p>
		 */
		public var hasDisableImage:Boolean = false;

		/** マウスオーバー状態が解除されるときの遷移先フレーム　*/
		protected var saveFrameNo:int;
		/** 有効・無効フラグ */
		protected var enableFlg:Boolean;
		/** クリック時に実行される関数 */
		protected var clickFunction:Function;
		/** clickFunction に渡されるデータ */
		protected var clickData:Object;
		/** マウスオーバー時のビジュアルがあるかどうか */
		protected var hasOverImage:Boolean = false;
		/** マウスダウン時のビジュアルがあるかどうか */
		protected var hasMouseDownImage:Boolean = false;
		/** マウスオーバー時のビジュアルのフレームラベル */
		protected static const mouseOverLabel:String = "l_over";
		/** OFF時のビジュアルのフレームラベル */
		protected static const offLabel:String = "l_off";
		/** ON時のビジュアルのフレームラベル */
		protected static const onLabel:String = "l_on";
		/** 機能無効化時のビジュアルのフレームラベル */
		protected static const disableLabel:String = "l_disable";
		/** マウスダウン時のビジュアルのフレームラベル */
		protected static const mouseDownLabel:String = "l_down";
		
		/**
		 * ボタンクリック時に実行される関数を設定する.
		 * 
		 * @param	fnc	起動する関数
		 * @param	obj	関数に渡すパラメータ
		 */
		public function setClickFunc(fnc: Function, obj:Object):void
		{
			clickFunction = fnc;
			clickData = obj;
		}

		/**
		 * mouseOverイベントリスナー.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		protected function mouseOverHandler(event:Event):void
		{
			this.gotoAndStop(mouseOverLabel);
		}

		/**
		 * mouseOutイベントリスナー.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		protected function mouseOutHandler(event:Event):void
		{
			this.gotoAndStop(saveFrameNo);
		}

		/**
		 * mouseDownイベントリスナー.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		protected function mouseDownHandler(event:Event):void
		{
			this.gotoAndStop(mouseDownLabel);
		}

		/**
		 * mouseUpイベントリスナー.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		protected function mouseUpHandler(event:Event):void
		{
			this.gotoAndStop(saveFrameNo);
		}

		/**
		 * クリックイベントリスナー.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		protected function clickHandler(event:MouseEvent):void
		{
			if (clickFunction != null) {
				clickFunction(clickData);
			}
		}

		/**
		 * ボタンの機能の有効・無効設定.
		 * 
		 * <p>外部で追加したイベントリスナーがある場合は、別途処理すること。</p>
		 * 
		 * <p>mouseEnabled と mouseChildren を使えば、個別にイベントリスナーを追加・解除しなくともまとめて切り替えられるが、
		 * その方法だと無効化時にマウスイベントが下のオブジェクトに通過してしまう。</p>
		 */
		public function get buttonEnabled():Boolean
		{
			return enableFlg;
		}

		public function set buttonEnabled(flg:Boolean):void
		{
			if (flg == enableFlg) {
				return;
			}
			if (flg) {
				if (hasOverImage) {
					addEventListener(FocusEvent.FOCUS_IN, mouseOverHandler, false, 0, true);
					addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler, false, 0, true);
					addEventListener(FocusEvent.FOCUS_OUT, mouseOutHandler, false, 0, true);
					addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler, false, 0, true);
				}
				if (hasMouseDownImage) {
					addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
					addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
				}
				addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
				enableFlg = true;
				if (hasDisableImage) {
					this.gotoAndStop(saveFrameNo);
				}
			} else {
				if (hasOverImage) {
					removeEventListener(FocusEvent.FOCUS_IN, mouseOverHandler);
					removeEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler);
					removeEventListener(FocusEvent.FOCUS_OUT, mouseOutHandler);
					removeEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler);
				}
				if (hasMouseDownImage) {
					removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
					removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				}
				removeEventListener(MouseEvent.CLICK, clickHandler);
				enableFlg = false;
				if (hasDisableImage) {
					this.gotoAndStop(disableLabel);
				}
			}
		}
		
		/**
		 * コンストラクタ.
		 */
		public function SimpleButtonBase()
		{
			this.gotoAndStop(1);
			var labels:Array = currentLabels;
			var label:FrameLabel;
			for (var i:uint = 0; i < labels.length; i++) {
				label = labels[i] as FrameLabel;
				switch (label.name) {
				case mouseOverLabel:
					hasOverImage = true;
					break;
				case mouseDownLabel:
					hasMouseDownImage = true;
					break;
				case disableLabel:
					hasDisableImage = true;
					break;
				}
			}
			if (hasOverImage) {
				addEventListener(FocusEvent.FOCUS_IN, mouseOverHandler, false, 0, true);
				addEventListener(MouseEvent.MOUSE_OVER, mouseOverHandler, false, 0, true);
				addEventListener(FocusEvent.FOCUS_OUT, mouseOutHandler, false, 0, true);
				addEventListener(MouseEvent.MOUSE_OUT, mouseOutHandler, false, 0, true);
			}
			if (hasMouseDownImage) {
				addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler, false, 0, true);
				addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler, false, 0, true);
			}
			addEventListener(MouseEvent.CLICK, clickHandler, false, 0, true);
			saveFrameNo = 1;
			enableFlg = true;
		}
	}
}