// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import flash.display.*;
	import flash.events.*;
	import fl.video.*; 
	import flash.net.NetStream;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import UtilFuncs;

	/**
	 * プレーヤークラス
	 */
	public class Player3Videos extends MovieClip
	{
		/** 映像を再生するプレイヤーオブジェクト */
		public var player:FLVPlayback;
		/** エフェクト表示領域 */
		public var mcEffectScreen:MovieClip;
		/** エフェクトの表示範囲を映像に合わせるためのマスク */
		public var mcEffectMask:MovieClip;
		
		/** ビデオプレイヤーの個数 */
		public const VIDEO_PLAYERS_COUNT:uint = 3;
		
		/** 状態を表す定数: ポーズ */
		public static const MODE_PAUSE:uint = 0;
		/** 状態を表す定数: 再生 */
		public static const MODE_PLAY:uint = 1;
		/** 状態を表す定数: スロー再生 */
		public static const MODE_SLOW:uint = 2;
		/** 状態を表す定数: 高速再生(未使用) */
		public static const MODE_FAST:uint = 3;
		/** 状態を表す定数: 選択区間再生 */
		public static const MODE_RANGE:uint = 4;
		/** 状態を表す定数: 選択区間再生後の停止状態 */
		public static const MODE_RANGE_END:uint = 5;
		/** 状態を表す定数: 逆再生(未使用) */
		public static const MODE_REVERSE:uint = 6;
		/** 状態を表す定数: 区間指定スロー再生 */
		public static const MODE_RANGE_SLOW:uint = 7;
		/** 状態を表す定数: 区間指定高速再生(未使用) */
		public static const MODE_RANGE_FAST:uint = 8;
		/** 状態を表す定数: 区間指定逆再生(未使用) */
		public static const MODE_RANGE_REVERSE:uint = 9;
		
		/** 選択区間チェック間隔 */
		const RANGE_CHECK_INTERVAL:Number = 250;
		/** 選択区間チェック起動タイマー */
		protected var rangeCheckTimer:Timer = new Timer(RANGE_CHECK_INTERVAL, 0);
		/** 選択区間開始時間 */
		protected var rangeStart:Number = 0;
		/** 選択区間終了時間 */
		protected var rangeEnd:Number = Number.MAX_VALUE;
		/** 繰り返しモードフラグ */
		protected var isRangeRepeat:Boolean;
		/** 選択区間チェックフラグ */
		protected var rangeCheckFlg:Boolean = false;

		/** オブジェクトの状態 */
		protected var mode:uint = MODE_PAUSE;
		/** シーク中フラグ */
		protected var flgSeeking:Boolean = false;
		/** シーク中の次のシーク要求発生フラグ */
		protected var flgWaitSeek:Boolean = false;
		/** 目標のシーク先 */
		protected var gotoTime:Number;
		/** シーク時に再試行するか */
		protected var needRetrySeek:Boolean;
		/** スマートシーク可否チェック済みフラグ */
		protected var inBufferChecked:Vector.<Boolean> = new Vector.<Boolean>(VIDEO_PLAYERS_COUNT);
		/** スマートシーク可否フラグ */
		protected var inBufferOK:Vector.<Boolean> = new Vector.<Boolean>(VIDEO_PLAYERS_COUNT);
		/** 一度も再生ヘッドが動いていない場合にfalse */
		protected var flgMoved:Boolean = false;
		/** 再生速度 */
		protected var playSpeed:Number = 0;
		
		/** フレーム間隔(フレームレートの逆数) */
		protected var framePitch:Vector.<Number> = new Vector.<Number>(VIDEO_PLAYERS_COUNT);
		
		/** 映像切替時に行う追加処理 */
		protected var onChangeVideoFunc:Function;
		/** onChangeVideoFunc に渡すデータ */
		protected var onChangeVideoData:Object;
		
		/** 再生制御系タイマー呼び出し間隔 */
		const intvlunit:Number = /*300*/ 100;
		/** 再生速度制御タイマー */
		private var ffRewTimer:Timer = new Timer(intvlunit, 0);
		private var ffRawDeltaTime:Number = intvlunit / 1000;
		private var ffRawTimePos:Number = 0;
		/** スロー再生制御用タイマー */
		private var slowTimer:Timer = new Timer(intvlunit, 1);
		/** 状態チェックタイマー */
		private var stateCheckTimer:Timer = new Timer(intvlunit, 0);
		/** 再生中状態への移行待ちフラグ */
		private var flgWaitPlay:Boolean = false;
		/** 表示映像切替待ちフラグ */
		private var flgChangeShowCh:Boolean = false;
		/** シーク前の時間 */
		private var orgTime:Number;
		/** 再試行シーク先時間 */
		private var gotoTimeRetry:Number;
		/** シーク再試行時の gotoTimeRetry の増分 */
		private var gotoRetryDelta:Number = 0.1;
		/** シーク試行回数 */
		private var seekcount:uint = 0;
		/** みなしキーフレーム間隔 */
		protected var deemedKeyFramePitchArr:Vector.<Number> = new Vector.<Number>(VIDEO_PLAYERS_COUNT);
		/** シーク先の誤差の履歴の個数 */
		private const GOTO_VARIATION_HISTORY_COUNT:uint = 4;
		/** シーク先の目標値と実際の値の誤差の履歴。キーフレームの間隔の目安とする。 */
		private var gotoTimeVariationHistory:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(VIDEO_PLAYERS_COUNT);
		/** シーク先の誤差の履歴のインデックス */
		private var variationHistoryIdx:Vector.<uint> = new Vector.<uint>(VIDEO_PLAYERS_COUNT);
		
		/** スマートシーク設定時のバッファ */
		const SMART_SEEK_BUFFER_TIME:Number = 15;
		
		/**
		 * コンストラクタ.
		 */
		public function Player3Videos()
		{
			for (var i:uint = 0; i < VIDEO_PLAYERS_COUNT; ++i) {
				inBufferChecked[i] = false;
				inBufferOK[i] = false;
				framePitch[i] = 0;
				deemedKeyFramePitchArr[i] = 0;
				gotoTimeVariationHistory[i] = new Vector.<Number>(GOTO_VARIATION_HISTORY_COUNT);
				for (var j:uint = 0; j < GOTO_VARIATION_HISTORY_COUNT; ++j) {
					gotoTimeVariationHistory[i][j] = 0;
				}
				variationHistoryIdx[i] = 0;
			}

			rangeCheckTimer.stop();
			ffRewTimer.stop();
			slowTimer.stop();
			stateCheckTimer.addEventListener(TimerEvent.TIMER, stateCheckHandler);
			stateCheckTimer.start();
			mcEffectScreen.mask = mcEffectMask;
			player.fullScreenTakeOver = false;
			player.addEventListener(MetadataEvent.METADATA_RECEIVED, metadataReceivedHandler);
		}
		
		/**
		 * 映像切替完了時に実行する処理を設定.
		 * 
		 * @param	fnc		起動する関数
		 * @param	data	関数に渡すパラメータ
		 */
		public function setOnChangeVideoFunc(fnc:Function, data:Object):void
		{
			onChangeVideoFunc = fnc;
			onChangeVideoData = data;
		}
		
		/**
		 * 再生する映像
		 */
		public function set videoSource(srcStr:String):void
		{
			player.source = srcStr;
		}

		/**
		 * 表示映像切替完了後に起動し、エフェクト表示領域の位置とサイズを新しい映像に合わせて更新する。
		 */
		protected function afterChngVideo():void
		{
			mcEffectScreen.x = player.x;
			mcEffectScreen.y = player.y;
			mcEffectMask.x = player.x;
			mcEffectMask.y = player.y;
			mcEffectMask.width = player.width;
			mcEffectMask.height = player.height;
			if (onChangeVideoFunc != null) {
				onChangeVideoFunc(onChangeVideoData);
			}
		}
		
		/**
		 * 映像を切り替えて、元の映像と同じ時間にシークする.
		 * 
		 * <p>ポーズ状態でシークすると Seeked イベントが捕捉できず、 stateCheckTimer の Timer イベントが
		 * シーク完了状態を検知するのを待つことになり時間が掛かるので、再生状態で切り替えるときは以下の順序で処理を行う。</p>
		 * <ul>
		 * <li>元の映像をポーズ</li>
		 * <li>操作対象映像切替</li>
		 * <li>再生開始</li>
		 * <li>再生状態に移行後にシーク</li>
		 * <li>シーク完了後に 表示映像切替</li>
		 * </ul>
		 * 
		 * <p>ポーズ状態で切り替えるときは、 stateCheckTimer の Timer イベントでシーク完了を検知して表示映像を切り替える。</p>
		 * 
		 * @param	num		切替先映像番号
		 */
		public function chngVideo(num:int):void
		{
			var svmode:uint = mode;
			if (svmode != MODE_PAUSE) {
				pauseVideo();
			}
			var nowtime:Number = player.playheadTime;
			player.activeVideoPlayerIndex = num;
			switch (svmode) {
			case MODE_FAST:
			case MODE_SLOW:
			case MODE_REVERSE:
			case MODE_PLAY:
				playVideo(playSpeed);
				break;
			case MODE_RANGE_FAST:
			case MODE_RANGE_SLOW:
			case MODE_RANGE_REVERSE:
			case MODE_RANGE:
				speedRangePlayVideo(playSpeed,-1, -1, false);
				break;
			case MODE_RANGE_END:
				mode = svmode;
				break;
			}
			if (flgMoved) {
				if ((mode == MODE_PAUSE) || (mode == MODE_RANGE_END)) {
					seekVideo(nowtime);
				} else {
					//再生状態に移行してからシーク
					player.addEventListener(VideoEvent.PLAYING_STATE_ENTERED, playingStateEnteredThenSeek);
					flgWaitPlay = true;
					gotoTime = nowtime;
				}
				//シーク後に表示映像切替
				flgChangeShowCh = true;
			} else {
				player.visibleVideoPlayerIndex  = num;
				afterChngVideo();
			}
		}
		
		/**
		 * 変速再生終了処理
		 */
		protected function endVariableSpeed():void
		{
			if (ffRewTimer.running) {
				ffRewTimer.reset();
				ffRewTimer.removeEventListener(TimerEvent.TIMER, ffRewTimerHandler);
			}
			if (slowTimer.running) {
				slowTimer.reset();
				slowTimer.removeEventListener(TimerEvent.TIMER, slowTimerHandler);
			}
		}
		
		/**
		 * ムービーの再生.
		 * 
		 * <p>スロー再生の場合は、 ffRewTimer と、 ffRewTimer の Timer イベント毎に
		 * ffRewTimer の　speed 倍の間隔で起動する slowTimer を起動し、
		 * ffRewTimer の Timer イベントで再生開始、　slowTimer の Timer イベントでポーズすることで
		 * 擬似的にスロー再生させる。</p>
		 * 
		 * @param	speed	再生速度
		 */
		public function playVideo(speed:Number = 1):void
		{
			endRangeCheck();
			flgMoved = true;
			playSpeed = speed;
			endVariableSpeed();
			if (speed == 1) {
				mode = MODE_PLAY;
				player.play();
			} else {
				//player.play();
				player.ncMgr.videoPlayer.netStream.pause();
				//player.pause();
				if (speed != 0) {
					ffRawTimePos = player.playheadTime;
					ffRawDeltaTime = intvlunit * speed / 1000;
					ffRewTimer.addEventListener(TimerEvent.TIMER, ffRewTimerHandler);
					ffRewTimer.start();
					if (speed > 1) {
						mode = MODE_FAST;
					} else if (speed > 0) {
						mode = MODE_SLOW;
						slowTimer.delay = intvlunit * speed;
						slowTimer.addEventListener(TimerEvent.TIMER, slowTimerHandler);
						slowTimer.start();
						player.play();
					} else {
						mode = MODE_REVERSE;
					}
				}
			}
		}
		
		/**
		 * ポーズ
		 */
		public function pauseVideo():void
		{
			endRangeCheck();
			endVariableSpeed();
			player.pause();
			mode = MODE_PAUSE;
		}
		
		/**
		 * 繰り返し再生モード
		 */
		public function get rangeRepeat():Boolean
		{
			return isRangeRepeat;
		}

		public function set rangeRepeat(sw:Boolean):void
		{
			isRangeRepeat = sw;
			if (sw && (mode == MODE_RANGE_END)) {
				rangePlay();
			}
		}
		
		/**
		 * 選択区間開始時間
		 */
		public function get playRangeStart():Number
		{
			return rangeStart;
		}
		
		public function set playRangeStart(startTime:Number):void
		{
			if (startTime >= 0) {
				rangeStart = startTime;
			}
		}

		/**
		 * 選択区間終了時間
		 */
		public function get playRangeEnd():Number
		{
			return rangeEnd;
		}
		
		public function set playRangeEnd(endTime:Number):void
		{
			if (endTime >= 0) {
				rangeEnd = endTime;
			}
		}
		
		/**
		 * 速度と再生区間を指定して再生
		 * 
		 * @param	speed
		 * @param	startTime
		 * @param	endTime
		 * @param	fromStartTime
		 */
		public function speedRangePlayVideo(speed:Number = 1, startTime:Number = -1, endTime:Number = -1, fromStartTime:Boolean = false):void
		{
			endRangeCheck();
			flgMoved = true;
			playSpeed = speed;
			endVariableSpeed();
			if (startTime >= 0) {
				rangeStart = startTime;
			}
			if (endTime >= 0) {
				rangeEnd = endTime;
			}
			rangeCheckTimer.reset();
			rangeCheckTimer.addEventListener(TimerEvent.TIMER, rangeCheckHandler);
			rangeCheckTimer.start();
			player.addEventListener(VideoEvent.COMPLETE, rangeCheckHandlerForComp);
			if (speed == 1) {
				mode = MODE_RANGE;
				player.play();
			} else {
				player.ncMgr.videoPlayer.netStream.pause();
				if (speed != 0) {
					ffRawTimePos = player.playheadTime;
					ffRawDeltaTime = intvlunit * speed / 1000;
					ffRewTimer.addEventListener(TimerEvent.TIMER, ffRewTimerHandler);
					ffRewTimer.start();
					if (speed > 1) {
						mode = MODE_RANGE_FAST;
					} else if (speed > 0) {
						mode = MODE_RANGE_SLOW;
						slowTimer.delay = intvlunit * speed;
						slowTimer.addEventListener(TimerEvent.TIMER, slowTimerHandler);
						slowTimer.start();
						player.play();
					} else {
						mode = MODE_RANGE_REVERSE;
					}
				}
			}
			rangeCheckFlg = true;
			if (fromStartTime) {
				player.addEventListener(VideoEvent.PLAYING_STATE_ENTERED, playingStateEnteredThenSeek);
				//seekVideo(rangeStart);
				flgWaitPlay = true;
				gotoTime = rangeStart;
			}
		}
		
		/**
		 * 選択区間再生モード.
		 * 
		 * @param	startTime		区間開始時間(-1の場合は元の時間を維持)
		 * @param	endTime			区間終了時間(-1の場合は元の時間を維持)
		 * @param	fromStartTime	開始時に区間先頭へシークするかどうか
		 */
		public function rangePlay(startTime:Number = -1, endTime:Number = -1, fromStartTime:Boolean = true):void
		{
			endVariableSpeed();
			flgMoved = true;
			if (startTime >= 0) {
				rangeStart = startTime;
			}
			if (endTime >= 0) {
				rangeEnd = endTime;
			}
			rangeCheckTimer.reset();
			rangeCheckTimer.addEventListener(TimerEvent.TIMER, rangeCheckHandler);
			rangeCheckTimer.start();
			player.addEventListener(VideoEvent.COMPLETE, rangeCheckHandlerForComp);
			mode = MODE_RANGE;
			rangeCheckFlg = true;
			player.play();
			if (fromStartTime) {
				player.addEventListener(VideoEvent.PLAYING_STATE_ENTERED, playingStateEnteredThenSeek);
				//seekVideo(rangeStart);
				flgWaitPlay = true;
				gotoTime = rangeStart;
			}
		}
		
		/**
		 * 選択区間チェック解除処理.
		 */
		protected function endRangeCheck():void
		{
			if (!rangeCheckFlg /*mode != MODE_RANGE*/) {
				return;
			}
			rangeCheckTimer.stop();
			rangeCheckTimer.removeEventListener(TimerEvent.TIMER, rangeCheckHandler);
			player.removeEventListener(VideoEvent.COMPLETE, rangeCheckHandlerForComp);
			rangeCheckFlg = false;
		}
		
		/**
		 * 選択区間チェック用タイマイベントハンドラ.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		protected function rangeCheckHandler(event:TimerEvent):void
		{
			if (player.state == VideoState.SEEKING) {
				return;
			}
			var nowtime:Number = player.playheadTime;
			if (nowtime > rangeEnd) {
				if (isRangeRepeat) {
					seekVideo(rangeStart);
				} else {
					player.pause();
					endRangeCheck();
					mode = MODE_RANGE_END;
				}
			}
		}
		
		/**
		 * 選択区間チェック用イベントハンドラ.
		 * 
		 * <p>範囲チェックをすり抜けて再生が終了した場合用。</p>
		 * 
		 * @param	event	イベントオブジェクト
		 */
		protected function rangeCheckHandlerForComp(event:VideoEvent):void
		{
			if (isRangeRepeat) {
				seekVideo(rangeStart);
			} else {
				player.pause();
				endRangeCheck();
				mode = MODE_RANGE_END;
			}
		}
		
		/**
		 * フレームレート取得判定
		 * 
		 * @return	true: 取得済み / false: 未取得
		 */
		protected function hasFramePitch():Boolean
		{
			var idx:uint = player.activeVideoPlayerIndex;
			if (framePitch[idx] != 0) {
				return true;
			}
			if (player.isRTMP) {
				if (player.metadata.hasOwnProperty("framerate")) {
					if (player.metadata.framerate != 0) {
						framePitch[idx] = 1 / player.metadata.framerate;
					}
				}
			} else {
				if (player.metadata.hasOwnProperty("videoframerate")) {
					if (player.metadata.videoframerate != 0) {
						framePitch[idx] = 1 / player.metadata.videoframerate;
					}
				}
			}
			return framePitch[idx] != 0;
		}
		
		/**
		 * 1フレーム送り・戻し
		 * 
		 * @param	direction	正数で1フレーム送り、負数で1フレーム戻し
		 */
		public function stepFrame(direction:int):void
		{
			if (!hasFramePitch()) {
				return;
			}

			if (flgSeeking) {
				if (direction < 0) {
					gotoTime -= framePitch[player.activeVideoPlayerIndex];
				} else {
					gotoTime += framePitch[player.activeVideoPlayerIndex];
				}
				flgWaitSeek = true;
			} else {
				if (direction < 0) {
					seekVideo(player.playheadTime - framePitch[player.activeVideoPlayerIndex], true);
				} else {
					seekVideo(player.playheadTime + framePitch[player.activeVideoPlayerIndex], true);
				}
			}
		}
		
		/**
		 * 1秒送り・戻し
		 * 
		 * @param	direction	正数で1秒送り、負数で1秒戻し
		 */
		public function stepSecond(direction:int):void
		{
			if (flgSeeking) {
				if (direction < 0) {
					gotoTime -= 1;
				} else {
					gotoTime += 1;
				}
				flgWaitSeek = true;
			} else {
			//if (player.isRTMP) {
				if (direction < 0) {
					seekVideo(player.playheadTime - 1, hasFramePitch());
				} else {
					seekVideo(player.playheadTime + 1, hasFramePitch());
				}
			//}
			}
		}
		
		/**
		 * 指定の時間へシークを行う.
		 * 
		 * <p>シーク動作を開始し、シーク完了を待つ。
		 * プレイヤーが停止中の場合は、 Seeked　イベントが発生しないようなので、イベントリスナーを登録しない。</p>
		 * <p>すでにシーク中の場合は、今のシークが完了してから実行するように待ち状態をセットする。</p>
		 * <p>1コマ送りのように、「最も近いキーフレーム」よりも「指定方向の次のキーフレームへ動く」ことが重要な場合は、
		 * 移動後の位置を元の位置および指定した移動先と比較し、必要に応じて移動量を増加させて再試行を行う。</p>
		 * 
		 * @param	time			シーク先
		 * @param	needRetryFlg	移動量をチェックして再試行するかどうか
		 */
		public function seekVideo(time:Number, needRetryFlg:Boolean = false):void
		{
			//trace("seek to ", time);
			if (time < 0) {
				time = 0;
				needRetryFlg = false;
			}
			//最小移動量はみなしキーフレーム間隔の半値。
			gotoRetryDelta = deemedKeyFramePitchArr[player.activeVideoPlayerIndex] / 2;
			seekcount = 0;
			if (flgSeeking) {
				//既にシーク中の場合はシーク先を更新。
				//今のシークが完了したときに次のシークが行われる。
				gotoTime = time;
				gotoTimeRetry = time;
				//needRetryFlg が true でも、シーク先が最初の位置と同じになる場合は、終わらなくなるので再試行しない。
				needRetrySeek = (gotoTime == orgTime)? false:needRetryFlg;
				flgWaitSeek = true;
			} else {
				//シークを開始する場合
				orgTime = player.playheadTime;
				gotoTime = time;
				//移動量が0の場合はシークしない。
				if (orgTime != gotoTime) {
					//キーフレーム間隔より細かい精度は出せないので、移動量の最小値は、キーフレーム間隔の半分(推定)とする。
					if (orgTime < gotoTime) {
						gotoTimeRetry = Math.max(gotoTime, (orgTime + gotoRetryDelta));
					} else {
						gotoTimeRetry = Math.min(gotoTime, (orgTime - gotoRetryDelta));
					}
					needRetrySeek = needRetryFlg;
					flgMoved = true;
					stateCheckTimer.reset();
					stateCheckTimer.start();
					if ((mode != MODE_PAUSE) && (mode != MODE_RANGE_END)) {
						player.addEventListener(VideoEvent.SEEKED, seekedHandler);
					}
					player.seek(gotoTimeRetry);
					flgSeeking = true;
				}
			}
		}
		
		/**
		 * 再生ヘッド時間
		 */
		public function get playheadTime():Number
		{
			return player.playheadTime;
		}
		
		/**
		 * みなしキーフレーム間隔
		 */
		public function get deemedKeyFramePitch():Number
		{
			return deemedKeyFramePitchArr[player.activeVideoPlayerIndex];
		}
		
		/**
		 * シーク中かどうか.
		 * 
		 * <p>シーク中と映像切替中に true を返す。</p>
		 */
		public function get isSeeking():Boolean
		{
			return flgSeeking || flgChangeShowCh;
		}

		/**
		 * シーク完了時処理.
		 * 
		 * <p>表示映像の切替待ちの場合は表示映像を切り替える。</p>
		 * <p>次のシークが待たれている場合は、次のシークを行う。</p>
		 * <p>シーク待ちが無い場合、現在の位置を元の位置と目標のシーク先と比較し、
		 * 元の位置の方に近い場合はシーク不足として目標を遠くへずらしてリトライする。</p>
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function seekedHandler(event:VideoEvent):void
		{
			var playerIdx:uint = player.activeVideoPlayerIndex;
			if (flgChangeShowCh) {
				//映像を切り替える場合
				player.visibleVideoPlayerIndex  = playerIdx;
				afterChngVideo();
				flgChangeShowCh = false;
			}
			if (flgWaitSeek) {
				//シーク待ちがある
				if (gotoTime < 0) {
					gotoTime = 0;
					needRetrySeek = false;
				}
				player.seek(gotoTime);
				flgWaitSeek = false;
			} else {
				//シーク待ちが無い
				var nowtime:Number = player.playheadTime;
				//trace("now ", nowtime);
				if (needRetrySeek && Math.abs(nowtime-orgTime) < Math.abs(nowtime-gotoTime)) {
					//現在位置が目標のシーク先よりも元の位置の方に近い場合、移動量を増やして再試行
					if (gotoTime > nowtime) {
						gotoTimeRetry += gotoRetryDelta;
					} else {
						gotoTimeRetry -= gotoRetryDelta;
						if (gotoTimeRetry < 0) {
							gotoTimeRetry = 0;
							needRetrySeek = false;
						}
					}
					//trace("goto retry to ", gotoTimeRetry, " , delta = ", gotoRetryDelta);
					gotoRetryDelta *= 2;
					++seekcount;
					player.seek(gotoTimeRetry);
				} else {
					//シーク完了
					if (player.hasEventListener(VideoEvent.SEEKED)) {
						player.removeEventListener(VideoEvent.SEEKED, seekedHandler);
					}
					if (needRetrySeek) {
						//シーク先の誤差を記憶
						gotoTimeVariationHistory[playerIdx][variationHistoryIdx[playerIdx]] = Math.abs(nowtime-gotoTime);
						variationHistoryIdx[playerIdx] = (variationHistoryIdx[playerIdx] + 1) % GOTO_VARIATION_HISTORY_COUNT;
						//最大の誤差をキーフレーム間隔と見なして、その半値を次回のシークの最小移動量とする。
						//ただし、誤差の少ない状態が続いた場合は値が小さくなりすぎるので、フレーム間隔を下回らないものとする。
						deemedKeyFramePitchArr[playerIdx] = gotoTimeVariationHistory[playerIdx][0];
						for (var i:uint = 1; i < GOTO_VARIATION_HISTORY_COUNT; ++i) {
							if (gotoTimeVariationHistory[playerIdx][i] > deemedKeyFramePitchArr[playerIdx]) {
								deemedKeyFramePitchArr[playerIdx] = gotoTimeVariationHistory[playerIdx][i];
							}
						}
						if (deemedKeyFramePitchArr[playerIdx] < framePitch[playerIdx]) {
							deemedKeyFramePitchArr[playerIdx] = framePitch[playerIdx];
						}
					}
					flgSeeking = false;
					//trace("seek error = ", nowtime-gotoTimeRetry);
					//trace("seek count = ", seekcount);
				}
			}
		}
		
		/**
		 * 再生状態移行後にシークを実行.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function playingStateEnteredThenSeek(event:VideoEvent):void
		{
			player.removeEventListener(VideoEvent.PLAYING_STATE_ENTERED, playingStateEnteredThenSeek);
			player.seek(gotoTime);
			flgWaitPlay = false;
			flgWaitSeek = false;
			flgSeeking = true;
		}
		
		/**
		 * 状態チェック用タイマイベントハンドラ.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function stateCheckHandler(event:TimerEvent):void
		{
			if (player.state == VideoState.SEEKING) {
				return;
			}
			if (flgWaitPlay) {
				//再生状態になったらシークするものがある
				if (player.state == VideoState.PLAYING) {
					playingStateEnteredThenSeek(new VideoEvent(VideoEvent.PLAYING_STATE_ENTERED));
				}
			} else if (flgSeeking) {
				//シーク完了後
				seekedHandler(new VideoEvent(VideoEvent.SEEKED));
			}
		}

		/**
		 * 変速再生用タイマイベントハンドラ
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function ffRewTimerHandler(event:TimerEvent):void {
			if ((mode == MODE_SLOW)||(mode == MODE_RANGE_SLOW)) {
				slowTimer.reset();
				slowTimer.start();
				player.play();
			} else {
				ffRawTimePos += ffRawDeltaTime;
				if (ffRawTimePos < 0) {
					ffRawTimePos = 0;
				} else if ((player.totalTime != 0) && (ffRawTimePos > player.totalTime)) {
					ffRawTimePos = player.totalTime;
				}
				player.ncMgr.videoPlayer.netStream.seek(ffRawTimePos);
				player.ncMgr.videoPlayer.netStream.resume();
			}
		}
		
		/**
		 * スロー再生用タイマイベントハンドラ.
		 * 
		 * <p>擬似的にスロー再生させるために、一定時間再生したらポーズさせるためのハンドラ。</p>
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function slowTimerHandler(event:TimerEvent):void
		{
			player.pause();
		}
		
		/**
		 * メタデータ受信イベントハンドラ.
		 * 
		 * <p>受信したメタデータよりフレームレートを取得する。
		 * 再生する映像がFMSからのストリーミング再生で、条件を満たせばスマートシークを設定する。</p>
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function metadataReceivedHandler(event:MetadataEvent):void
		{
			var targetPlayer:VideoPlayer = player.getVideoPlayer(event.vp);
			var targetStream:NetStream = targetPlayer.netStream;
			
			inBufferOK[event.vp] = false;
			inBufferChecked[event.vp] = true;
			if (targetPlayer.isRTMP) {
				try { 
					if (UtilFuncs.isFP10_1()) {
						targetStream.bufferTime = SMART_SEEK_BUFFER_TIME;
						targetStream.inBufferSeek = true;
						inBufferOK[event.vp] = true;
					}
				} catch (err:Error) {
					trace(err);
				}
			}

			if (event.info.hasOwnProperty("framerate") && (event.info.framerate != 0)) {
				framePitch[event.vp] = 1 / event.info.framerate;
			} else if (event.info.hasOwnProperty("videoframerate") && (event.info.videoframerate != 0)) {
				framePitch[event.vp] = 1 / event.info.videoframerate;
			}
			deemedKeyFramePitchArr[event.vp] = framePitch[event.vp];
		}
		
		/**
		 * 状態を返す
		 */
		public function get status():uint
		{
			return mode;
		}
	}
}