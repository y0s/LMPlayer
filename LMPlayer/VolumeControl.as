// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import fl.video.FLVPlayback;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;

	/**
	 * ボリュームスライダクラス.
	 * 
	 * <p>動画再生時の音量調整に使用するスライダ。</p>
	 * <p>ボリュームの値域は0～1とする。</p>
	 */
	public class VolumeControl extends MovieClip
	{
		/**
		 * ボリューム
		 */
		protected var volumeVal: Number = 1;
		/**
		 * ターゲットプレイヤー
		 */
		protected var targetPlayer: FLVPlayback;

		/** スライダー */
		public var mcSlider:MovieClip;
		/* バー */
		//public var mcTriangleBar:MovieClip;
		/** バーのベース */
		public var barBase:MovieClip;
		/** カラーバー */
		public var colorBar:MovieClip;
		/** カラーバーのマスク */
		public var volumeMask:MovieClip;
		/** スライダー可動領域最大値 */
		protected var SliderMoveMax:Number;
		/** ボリューム切替のステップ数 */
		public const volumeStepNumber:Number = 10;
		/** ドラッグ中フラグ */
		protected var flgDragging:Boolean = false;
		
		/**
		 * コンストラクタ
		 */
		public function VolumeControl()
		{
			SliderMoveMax = volumeMask.width;
			mcSlider.addEventListener(MouseEvent.MOUSE_DOWN, startSliderDrag);
			colorBar.mask = volumeMask;
			colorBar.mouseEnabled = false;
			volumeMask.mouseEnabled = false;
			//クリックイベントのリスナーの登録先を自分自身にすると、スライダー上をクリックした場合の処理は不要だが、
			//バー以外の部分(スピーカーマークなど)もクリックに反応する。
			this.addEventListener(MouseEvent.CLICK, barClickHandler);
			//クリックイベントのリスナーをバーの部分に登録した場合、クリックに反応するのはバーの上のみ。
			//スライダーの下になっている部分にはクリックが届かないので、スライダーがクリックされたらバーのクリックイベントを送出し直す。
			//barBase.addEventListener(MouseEvent.CLICK, barClickHandler);
			//mcSlider.addEventListener(MouseEvent.CLICK, sliderClickHandler);
		}

		/**
		 * スライダーをドラッグ中かどうか.
		 * 
		 * @return	true: ドラッグ中 / false: ドラッグ中でない
		 */
		public function isDragging():Boolean
		{
			return flgDragging;
		}
		
		/**
		 * スライダーの位置(0～1)
		 */
		public function get volume():Number
		{
			return volumeVal;
		}

		public function set volume(val: Number):void
		{
			if (val > 1) {
				volumeVal = 1;
			} else if (val < 0) {
				volumeVal = 0;
			} else {
				//volumeVal = Math.round(val * volumeStepNumber) / volumeStepNumber;
				volumeVal = val;
			}
			mcSlider.x = SliderMoveMax * volumeVal;
			volumeMask.x = SliderMoveMax * (volumeVal - 1);
		/*	if (targetPlayer) {
				targetPlayer.volume = volumeVal;
			}*/
		}
		
		/**
		 * 対象となるプレイヤーを指定する.
		 * 
		 * @param	target	対象となるプレイヤー
		 */
		public function setTargetPlayer(target: FLVPlayback): void
		{
			targetPlayer = target;
		}
		
		/**
		 * バークリック時処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function barClickHandler(event:MouseEvent):void
		{
			volumeVal = Math.round(event.currentTarget.mouseX / SliderMoveMax * volumeStepNumber) / volumeStepNumber;
			if (volumeVal < 0) {
				volumeVal = 0;
			} else if (volumeVal > 1) {
				volumeVal = 1;
			}
			mcSlider.x = volumeVal * SliderMoveMax;
			volumeMask.x = (volumeVal - 1) * SliderMoveMax;
			if (targetPlayer) {
				targetPlayer.volume = volumeVal;
			}
			
		}
		
		/**
		 * スライダ上をクリックした場合、バーのその直下の座標をクリックしたイベントを送出する。
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function sliderClickHandler(event:MouseEvent):void
		{
			var newevent:MouseEvent = new MouseEvent(MouseEvent.CLICK);
			newevent.localX = event.currentTarget.x - barBase.x + event.localX;
			newevent.localY = event.currentTarget.y - barBase.y + event.localY;
			barBase.dispatchEvent(newevent);
		}
		
		/**
		 * スライダードラッグ開始処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function startSliderDrag(event:MouseEvent):void
		{
			flgDragging = true;
			mcSlider.startDrag(false, new Rectangle(0, 0, SliderMoveMax, 0));
			//マウスがmcSliderからずれた場合のためにstageを対象にする。
			stage.addEventListener(MouseEvent.MOUSE_MOVE, moveVolFunc);
			stage.addEventListener(MouseEvent.MOUSE_UP, endSliderDrag);
		}
		
		/**
		 * スライダー移動処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function moveVolFunc(event:MouseEvent):void
		{
			volumeVal = Math.round(mcSlider.x / SliderMoveMax * volumeStepNumber) / volumeStepNumber;
			volumeMask.x = (volumeVal - 1) * SliderMoveMax;
			if (targetPlayer) {
				targetPlayer.volume = volumeVal;
			}
		}
		
		/**
		 * スライダードラッグ終了処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function endSliderDrag(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, moveVolFunc);
			stage.removeEventListener(MouseEvent.MOUSE_UP, endSliderDrag);
			moveVolFunc(event);
			mcSlider.stopDrag();
			flgDragging = false;
		}
	}
}