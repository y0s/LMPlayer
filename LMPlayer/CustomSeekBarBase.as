// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.geom.Rectangle;
	import fl.video.*;
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import UtilFuncs;
	import Player3Videos;

	/**
	 * シークバークラス.
	 * 
	 * <p>プレイヤーオブジェクトと連携し、現在の再生位置の表示や再生位置の移動を行うシークバーオブジェクト。
	 * 表示の更新は自動的には行わないので、適宜<code>updateView()</code>をコールすること。</p>
	 * 
	 * <p>再生マーカ、選択区間開始点マーカ、選択区間終了点マーカはそれぞれ以下のフレームを持つ。</p>
	 * <ul>
	 * <li>フレーム "l_normal" に通常時のデザイン。</li>
	 * <li>フレーム "l_over" にマウスオーバー時のデザイン。</li>
	 * <li>フレーム "l_active" にドラッグ時のデザイン。</li>
	 * </ul>
	 * 
	 * @see #updateView()
	 */
	public class CustomSeekBarBase extends MovieClip
	{
		/** 再生マーカ */
		public var mcPlayheadMarker:MovieClip;
		/** 選択区間開始点マーカ */
		public var mcRangeStMarker:MovieClip;
		/** 選択区間終了点マーカ */
		public var mcRangeEdMarker:MovieClip;
		/** 再生時刻表示ラベル */
		public var showPlayheadTime:TextField;
		/** 映像総時間表示ラベル */
		public var showTotalTime:TextField;
		/** タイムラインバーのベース */
		public var mcBarBase:MovieClip;
		/** タイムラインバーの選択区間を着色 */
		public var mcPlayRangeBar:MovieClip;
		
		/** 映像総時間 */
		protected var totalPlaytimeVal:Number = 0;

		/** 選択区間開始時刻 */
		protected var playRangeStartTime:Number = 0;
		/** 選択区間終了時刻 */
		protected var playRangeEndTime:Number = 0;
		/** ミリ秒まで表示するか */
		protected var usemsec:Boolean;
		protected const USE_MSEC_LENGTH:int = 12;
		
		/** ターゲットプレイヤー */
		protected var targetPlayer: FLVPlayback;
		/** ターゲットプレイヤー */
		protected var target3Video: Player3Videos;
		
		/** 再生マーカドラッグ中フラグ */
		protected var flgDraggingPlayhead:Boolean = false;
		/** 選択区間開始点マーカドラッグ中フラグ */
		protected var flgDraggingRangeSr:Boolean = false;
		/** 選択区間終了点マーカドラッグ中フラグ */
		protected var flgDraggingRangeEd:Boolean = false;
		/** 選択区間マーカードラッグ時処理 */
		protected var onDraggingRangeFunc:Function = null;
		
		/** 再生マーカy座標 */
		const YPOS_PLAYHEADMARKER:Number = 0;
		/** 選択区間マーカy座標 */
		const YPOS_RANGEMARKER:Number = 0;
		
		/** マーカーの通常時のビジュアルのフレームラベル */
		protected static const markerLabelNormal:String = "l_normal";
		/** マーカーのマウスオーバー時のビジュアルのフレームラベル */
		protected static const markerLabelMouseOver:String = "l_over";
		/** マーカーのドラッグ中のビジュアルのフレームラベル */
		protected static const markerLabelActive:String = "l_active";
		
		/**
		 * コンストラクタ
		 */
		public function CustomSeekBarBase()
		{
			if ((showPlayheadTime.length >= USE_MSEC_LENGTH) && (showTotalTime.length >= USE_MSEC_LENGTH)) {
				usemsec = true;
			} else {
				usemsec = false;
			}
			mcPlayheadMarker.addEventListener(MouseEvent.MOUSE_DOWN, startPlayheadMarkerDrag);
			mcPlayheadMarker.addEventListener(FocusEvent.FOCUS_IN, markerMouseOverHandler);
			mcPlayheadMarker.addEventListener(MouseEvent.MOUSE_OVER, markerMouseOverHandler);
			mcPlayheadMarker.addEventListener(FocusEvent.FOCUS_OUT, markerMouseOutHandler);
			mcPlayheadMarker.addEventListener(MouseEvent.MOUSE_OUT, markerMouseOutHandler);
			mcPlayheadMarker.gotoAndStop(markerLabelNormal);
			mcRangeStMarker.addEventListener(MouseEvent.MOUSE_DOWN, startRangeStMarkerDrag);
			mcRangeStMarker.addEventListener(FocusEvent.FOCUS_IN, markerMouseOverHandler);
			mcRangeStMarker.addEventListener(MouseEvent.MOUSE_OVER, markerMouseOverHandler);
			mcRangeStMarker.addEventListener(FocusEvent.FOCUS_OUT, markerMouseOutHandler);
			mcRangeStMarker.addEventListener(MouseEvent.MOUSE_OUT, markerMouseOutHandler);
			mcRangeStMarker.gotoAndStop(markerLabelNormal);
			mcRangeEdMarker.addEventListener(MouseEvent.MOUSE_DOWN, startRangeEdMarkerDrag);
			mcRangeEdMarker.addEventListener(FocusEvent.FOCUS_IN, markerMouseOverHandler);
			mcRangeEdMarker.addEventListener(MouseEvent.MOUSE_OVER, markerMouseOverHandler);
			mcRangeEdMarker.addEventListener(FocusEvent.FOCUS_OUT, markerMouseOutHandler);
			mcRangeEdMarker.addEventListener(MouseEvent.MOUSE_OUT, markerMouseOutHandler);
			mcRangeEdMarker.gotoAndStop(markerLabelNormal);
			mcPlayRangeBar.width = mcRangeEdMarker.x-mcRangeStMarker.x;
		}

		/**
		 * 選択区間マーカー移動時の追加処理
		 */
		public function set onDraggingRange(func: Function):void
		{
			onDraggingRangeFunc = func;
		}
		
		/**
		 * コンテンツの長さ(秒)
		 */
		public function set totalPlaytime(val:Number):void
		{
			totalPlaytimeVal = val;
			showTotalTime.text = UtilFuncs.secondToHMS(val, usemsec);
		}
		
		/**
		 * 再生ヘッド位置(秒)
		 */
		public function get playheadTime():Number
		{
			if (targetPlayer) {
				return targetPlayer.playheadTime;
			} else {
				return 0;
			}
		}

		public function set playheadTime(val: Number):void
		{
			if (targetPlayer) {
				targetPlayer.seek(val);
				this.updateView();
			}
		}

		/**
		 * 選択区間開始時間(秒).
		 * 
		 * <p>選択区間開始時間は終了時間より後になることは無い。</p>
		 */
		public function get playRangeStart():Number
		{
			return playRangeStartTime;
		}
		
		public function set playRangeStart(val:Number):void
		{
			if (totalPlaytimeVal == 0) {
				return;
			}
			if (val < 0) {
				mcRangeStMarker.x = 0;
				playRangeStartTime = 0; 
			} else if (val > playRangeEndTime) {
				mcRangeStMarker.x = mcRangeEdMarker.x;
				playRangeStartTime = playRangeEndTime;
			} else {
				mcRangeStMarker.x = mcBarBase.width * val / totalPlaytimeVal;
				playRangeStartTime = val;
			}
			mcPlayRangeBar.x = mcRangeStMarker.x;
			mcPlayRangeBar.width = mcRangeEdMarker.x-mcRangeStMarker.x;
		}

		/**
		 * 選択区間終了時間(秒).
		 * 
		 * <p>選択区間終了時間は開始時間より前になることは無い。</p>
		 */
		public function get playRangeEnd():Number
		{
			return playRangeEndTime;
		}
		
		public function set playRangeEnd(val:Number):void
		{
			if (totalPlaytimeVal == 0) {
				return;
			}
			if (val < playRangeStartTime) {
				mcRangeEdMarker.x = mcRangeStMarker.x;
				playRangeEndTime = playRangeStartTime;
			} else if (val > totalPlaytimeVal) {
				mcRangeEdMarker.x = mcBarBase.width;
				playRangeEndTime = totalPlaytimeVal;
			} else {
				mcRangeEdMarker.x = mcBarBase.width * val / totalPlaytimeVal;
				playRangeEndTime = val;
			}
			mcPlayRangeBar.width = mcRangeEdMarker.x-mcRangeStMarker.x;
		}

		/**
		 * 選択区間設定.
		 * 
		 * @param	startTime	区間開始時間(秒)
		 * @param	endTime		区間終了時間(秒)
		 */
		public function setPlayRange(startTime:Number, endTime:Number):void
		{
			var st:Number;
			var ed:Number;
			if (totalPlaytimeVal == 0) {
				return;
			}
			if (startTime <= endTime) {
				st = startTime;
				ed = endTime;
			} else {
				st = endTime;
				ed = startTime;
			}
			if (st < 0) {
				st = 0;
			}
			if (ed > totalPlaytimeVal) {
				ed = totalPlaytimeVal;
			}
			mcRangeStMarker.x = mcBarBase.width * st / totalPlaytimeVal;
			mcRangeEdMarker.x = mcBarBase.width * ed / totalPlaytimeVal;
			mcPlayRangeBar.x = mcRangeStMarker.x;
			mcPlayRangeBar.width = mcRangeEdMarker.x-mcRangeStMarker.x;
			playRangeStartTime = st;
			playRangeEndTime = ed;
			if (target3Video) {
				target3Video.playRangeStart = playRangeStartTime;
				target3Video.playRangeEnd = playRangeEndTime;
			}
		}
		
		/**
		 * 対象となるプレイヤーを指定する.
		 * 
		 * @param	target	対象となるプレイヤー
		 */
		public function setTargetPlayer(target:Player3Videos): void
		{
			targetPlayer = target.player;
			target3Video = target;
		}

		/**
		 * バーと時間の表示を更新.
		 * 
		 * <p>連携するプレイヤーの再生位置を取得し、表示を更新する。</p>
		 */
		protected function updateBarTime():Number
		{
			var now:Number = targetPlayer.playheadTime;
			if (now > totalPlaytimeVal) {
				now = totalPlaytimeVal;
			}
			showPlayheadTime.text = UtilFuncs.secondToHMS(now, usemsec);
			return now;
		}
		
		/**
		 * 表示の更新.
		 * 
		 * <p>連携するプレイヤーがシーク中でなければ、再生位置の表示を更新する。
		 * 再生マーカがドラッグ中でなければ再生マーカの位置も更新する。</p>
		 */
		public function updateView():void
		{
			var now:Number;
			if (totalPlaytimeVal == 0) {
				return;
			}
			// シーク中はバーを更新しない
			if (target3Video && !target3Video.isSeeking) {
				now = updateBarTime();
				if (!flgDraggingPlayhead) {
					mcPlayheadMarker.x = mcBarBase.width * now / totalPlaytimeVal;
				}
				if (!flgDraggingRangeSr && (target3Video.playRangeStart != playRangeStartTime)) {
					playRangeStart = target3Video.playRangeStart;
				}
				if (!flgDraggingRangeEd && (target3Video.playRangeEnd != playRangeEndTime)) {
					playRangeEnd = target3Video.playRangeEnd;
				}
			}
		}
		
		/**
		 * 再生マーカドラッグ開始処理.
		 * 
		 * @param	event	マウスイベント
		 */
		protected function startPlayheadMarkerDrag(event:MouseEvent):void
		{
			flgDraggingPlayhead = true;
			mcPlayheadMarker.startDrag(false, new Rectangle(0, YPOS_PLAYHEADMARKER, mcBarBase.width, 0));
			//マウスがmcSliderからずれた場合のためにstageを対象にする。
			stage.addEventListener(MouseEvent.MOUSE_MOVE, movePlayheadMarkerFunc);
			stage.addEventListener(MouseEvent.MOUSE_UP, endPlayheadMarkerDrag);
			mcPlayheadMarker.gotoAndStop(markerLabelActive);
		}
		
		/**
		 * 再生マーカ移動処理.
		 * 
		 * <p>マーカの位置対応する時間にプレイヤーをシークさせる。</p>
		 * 
		 * @param	event	マウスイベント
		 */
		protected function movePlayheadMarkerFunc(event:MouseEvent):void
		{
			var gotopos:Number = totalPlaytimeVal * (mcPlayheadMarker.x / mcBarBase.width);
			if (target3Video) {
				target3Video.seekVideo(gotopos);
			}
		}
		
		/**
		 * 再生マーカドラッグ終了処理.
		 * 
		 * @param	event	マウスイベント
		 */
		protected function endPlayheadMarkerDrag(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, movePlayheadMarkerFunc);
			stage.removeEventListener(MouseEvent.MOUSE_UP, endPlayheadMarkerDrag);
			mcPlayheadMarker.stopDrag();
			movePlayheadMarkerFunc(event);
			flgDraggingPlayhead = false;
			mcPlayheadMarker.gotoAndStop(markerLabelNormal);
		}
		
		/**
		 * 選択区間開始点マーカドラッグ開始処理.
		 * 
		 * @param	event	マウスイベント
		 */
		protected function startRangeStMarkerDrag(event:MouseEvent):void
		{
			flgDraggingRangeSr = true;
			mcRangeStMarker.startDrag(false, new Rectangle(0, YPOS_RANGEMARKER, mcRangeEdMarker.x, 0));
			//マウスがmcSliderからずれた場合のためにstageを対象にする。
			stage.addEventListener(MouseEvent.MOUSE_MOVE, moveRangeStMarkerFunc);
			stage.addEventListener(MouseEvent.MOUSE_UP, endRangeStMarkerDrag);
			mcRangeStMarker.gotoAndStop(markerLabelActive);
		}
		
		/**
		 * 選択区間開始点マーカ移動処理.
		 * 
		 * @param	event	マウスイベント
		 */
		protected function moveRangeStMarkerFunc(event:MouseEvent):void
		{
			mcPlayRangeBar.x = mcRangeStMarker.x;
			mcPlayRangeBar.width = mcRangeEdMarker.x-mcRangeStMarker.x;
			playRangeStartTime = totalPlaytimeVal * (mcRangeStMarker.x / mcBarBase.width);
			if (onDraggingRangeFunc != null) {
				onDraggingRangeFunc();
			}
		}
		
		/**
		 * 選択区間開始点マーカドラッグ終了処理.
		 * 
		 * @param	event	マウスイベント
		 */
		protected function endRangeStMarkerDrag(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, moveRangeStMarkerFunc);
			stage.removeEventListener(MouseEvent.MOUSE_UP, endRangeStMarkerDrag);
			mcRangeStMarker.stopDrag();
			moveRangeStMarkerFunc(event);
			if (target3Video) {
				target3Video.playRangeStart = playRangeStartTime;
			}
			flgDraggingRangeSr = false;
			mcRangeStMarker.gotoAndStop(markerLabelNormal);
		}
		
		/**
		 * 選択区間終了点マーカドラッグ開始処理.
		 * 
		 * @param	event	マウスイベント
		 */
		protected function startRangeEdMarkerDrag(event:MouseEvent):void
		{
			flgDraggingRangeEd = true;
			mcRangeEdMarker.startDrag(false, new Rectangle(mcRangeStMarker.x, YPOS_RANGEMARKER, mcBarBase.width - mcRangeStMarker.x, 0));
			//マウスがmcSliderからずれた場合のためにstageを対象にする。
			stage.addEventListener(MouseEvent.MOUSE_MOVE, moveRangeEdMarkerFunc);
			stage.addEventListener(MouseEvent.MOUSE_UP, endRangeEdMarkerDrag);
			mcRangeEdMarker.gotoAndStop(markerLabelActive);
		}
		
		/**
		 * 選択区間終了点マーカ移動処理.
		 * 
		 * @param	event	マウスイベント
		 */
		protected function moveRangeEdMarkerFunc(event:MouseEvent):void
		{
			mcPlayRangeBar.width = mcRangeEdMarker.x-mcRangeStMarker.x;
			playRangeEndTime = totalPlaytimeVal * (mcRangeEdMarker.x / mcBarBase.width);
			if (onDraggingRangeFunc != null) {
				onDraggingRangeFunc();
			}
		}
		
		/**
		 * 選択区間終了点マーカドラッグ終了処理.
		 * 
		 * @param	event	マウスイベント
		 */
		protected function endRangeEdMarkerDrag(event:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, moveRangeEdMarkerFunc);
			stage.removeEventListener(MouseEvent.MOUSE_UP, endRangeEdMarkerDrag);
			mcRangeEdMarker.stopDrag();
			moveRangeEdMarkerFunc(event);
			if (target3Video) {
				target3Video.playRangeEnd = playRangeEndTime;
			}
			flgDraggingRangeEd = false;
			mcRangeEdMarker.gotoAndStop(markerLabelNormal);
		}
		
		/**
		 * マーカ マウスオーバー時処理.
		 * 
		 * <p>マーカをマウスオーバー時の表示に更新する。</p>
		 * 
		 * @param	event	マウスイベント
		 */
		protected function markerMouseOverHandler(event:Event):void
		{
			event.currentTarget.gotoAndStop(markerLabelMouseOver);
		}
		
		/**
		 * マーカ マウスアウト時処理.
		 * 
		 * <p>マーカを通常時の表示に更新する。</p>
		 * 
		 * @param	event	マウスイベント
		 */
		protected function markerMouseOutHandler(event:Event):void
		{
			event.currentTarget.gotoAndStop(markerLabelNormal);
		}
	}
}