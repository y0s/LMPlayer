//
// DST Movie Viewer Document class
//
// Copyright (c) 2012 Kyoto University and DoGA
//

package {
	import fl.containers.ScrollPane;
	import fl.controls.List;
	import flash.display.*;
	import flash.events.*;
	import flash.net.drm.VoucherAccessInfo;
	import flash.text.TextField;	
	import flash.ui.Mouse;
	import flash.net.*;
	import flash.external.ExternalInterface;
	import fl.video.*; 
	import ToggleButtonBase;
	import RadioButtonBase;
	import CueItem;
	import EffectItem;
	import CaptionItem;
	import TransparentButton;
	import VolumeControl;
	import DualCaption;
	import Player3Videos;
	import PlayerControl;
	import PopupPlayerControl;
	import CustomSeekBarBase;
	import UtilFuncs;
	import BookmarkPane;
	import EffectControl;
	import EffectOnOff;

	/**
	 * ムービービューア ドキュメントクラス(メインとなるクラス).
	 * 
	 * <p>XMLファイルはFlashコンテンツを埋め込むHTMLファイルのobject要素内のparam要素で、
	 * 以下の要領で、「test.xml」の部分を読み込みたいファイル名に書き換えて指定する。</p>
	 * <listing version="3.0">&lt;param name="FlashVars" value="xmlfname=test.xml" /&gt;</listing>
	 * 
	 * <p>object要素は、IE用とその他のブラウザ用の２重になっているので注意。</p>
	 */	
	public class MovieViewer extends MovieClip {
	
		/** Javascriptとの連携をするか */
		const USE_JAVASCRIPT: Boolean = true;
		/** 映像の数 */
		const MOVIE_NUM:uint = 3;
		/** 映像あたりのエフェクトの数 */
		const EFFECT_NUM:uint = 4;
		/** 字幕の数 */
		const CAPTION_NUM:uint = 2;
		
		/** XMLファイル名を受け取るパラメーター名 */
		const XML_FILE_VARNAME:String = "xmlfname";
		/** パラメータでファイル名が与えられなかった場合のデフォルトの映像記述XMLファイル名 */
		const DEFAULT_XML_FILENAME:String = "test.xml";

		/** 起動時の頭出し開始時刻を受け取るパラメータ名 */
		const START_TIME_VARNAME:String = "sttime";
		/** 起動時の頭出し終了時刻を受け取るパラメータ名 */
		const END_TIME_VARNAME:String = "edtime";

		/** 矢印のエフェクトの識別名 */
		const EFFECT_TYPE_ARROW:String = "Arrow";
		/** 円のエフェクトの識別名 */
		const EFFECT_TYPE_CIRCLE:String = "Circle";
		/** 画像のエフェクトの識別名 */
		const EFFECT_TYPE_IMG:String = "Picture";
		
		/** オーバーラップするポップアップ操作パネルのアルファ値 */
		const POPUP_OVER_ALPHA:Number = 0.5;
		
		/** Matrixしおりのファイル名 */
		const MATRIX_HTML_FILE_NAME:String = "LMMatrix.html";
		/** マトリックスしおりを開くターゲット */
		const MATRIX_HTML_TARGET:String = "lmmatrix";
		
		/** 映像記述XMLファイル名 */
		var xmlName:String;
		/** 映像記述XMLの存在するパス */
		var xmlPathName:String;
		/** 映像ファイル名 */
		var movieFileName:Array;
		/** 映像のReady状態チェック */
		var movieReadyChk:Array;
		
		/** 映像の番号 */
		var movieIdx:int;
		/** エフェクトの番号 */
		var effectIdx:int;
		/** 字幕のインデックス */
		var captionIdx:int;
		/** しおりリスト・しおりクリッカブルマップ統一インデックス */
		var bookmarkIdx:int;
		/** しおりリストインデックス */
		var bookmarkListIdx:int;
		/** しおりクリッカブルマップ統一インデックス */
		var bookmarkMapIdx:int;
		
		/** エフェクトXMLファイル名 */
		var effectFileName:Vector.<Vector.<String>>;
		/** XMLファイル別のエフェクトデータの配列 */
		var effectArray:Vector.<Vector.<Vector.<EffectItem>>>;
		/** エフェクト制御オブジェクト */
		var effectControler:EffectControl = new EffectControl();
		/** エフェクトOn/Offボタン格納用配列 */
		var effectButtonArray:Vector.<LabeledToggleButton>;
		/** エフェクト表示初期状態 */
		var effSwInitialState:Vector.<Vector.<Boolean>>;
		/** エフェクトラベル */
		var effLabel:Vector.<Vector.<String>>;
		
		/** 字幕XMLファイル名 */
		var captionFileName:Vector.<String>;
		/** 読み込んだ字幕データ */
		var captionArray:Vector.<Vector.<CaptionItem>>;
		/** 字幕On/Offボタン格納用配列 */
		var capButtonArray:Vector.<ToggleButtonBase>;
		
		/** しおりリストXMLファイル名 */
		var bookmarkListFileName:Vector.<String>;
		/** しおりクリッカブルマップXMLファイル名 */
		var bookmarkMapFileName:Vector.<String>;
		
		/** 映像の長さ(秒) */
		var movieLength:Number = 0;
		
		/** 選択中の映像の番号 */
		var selectedVideo:int = -1;
		
		/**	起動時の頭出し開始時間 */
		var startTimeOnLoaded:Number = -1;
		/**	起動時の頭出し終了時間 */
		var endTimeOnLoaded:Number = -1;
		
		/** ファイルの読み込みに使用する URLLoader オブジェクト */
		var loader:URLLoader;
		/** ファイルへのアクセスに使用する URLRequest オブジェクト */
		var request:URLRequest;
		
		/** 戻るボタンの戻り先URL */
		var returnUrl:String = "index.html";
		
		var player_orig_x:Number;
		var player_orig_y:Number;
		var player_full_x:Number;
		var player_full_y:Number;
		var player_full_scale:Number = 1;
		
		/** 音量バーの1目盛りの半分の幅 */
		var half_volume_step:Number;
		
		/** 準備完了までの目隠し */
		public var mcShutter:MovieClip;
		/** 映像選択ボタン管理用配列 */
		public var selVideoBtnArr:Array = new Array();
		/** プレイヤー操作部(通常表示時) */
		public var mcPlayerControl:PlayerControl;
		/** プレイヤー操作部(フルスクリーン表示時) */
		public var mcPopupPlayerControl:PopupPlayerControl;
		/** フルスクリーン表示時のプレイヤー操作部以外のクリック検知用 */
		public var mcUnderPopup:MovieClip;
		/** プレイヤー部 */
		public var mc_player:Player3Videos;
		/** 字幕表示部(通常表示時) */
		public var mc_Caption:DualCaption;
		/** 字幕表示部(フルスクリーン表示時) */
		public var mc_CaptionFull:MovieClip;
		/** ファイル名表示部 */
		public var dispFilename:TextField;
		/** 「戻る」ボタン */
		public var bReturn:SimpleButton;
		/** 「表の表示」ボタン */
		public var bMatrix:SimpleButton;
		/** シーン情報表示部 */
		public var mcBookmarkPane:BookmarkPane;
		/** エフェクト表示切り替えボタンを保持するオブジェクト */
		public var mcEffectButtons:EffectOnOff;
		/** フルスクリーン表示時背景 */
		public var FullBG:MovieClip;
		/** 初期設定に戻るボタン */
		public var bReset:SimpleButtonBase;
		
		/**
		 * ファイル読み込みエラー時処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function loaderErrorHandler(event:ErrorEvent):void
		{
			mcShutter.tSetupReport.appendText("\n" + event.toString());
		}
		
		/**
		 * 相対パスを映像記述XMLファイルの位置基準のパスにする
		 * 絶対パスはそのまま返す
		 * @param	path	元のパス
		 * @return	調整後のパス
		 */
		public function relativePathFromXML(path:String):String
		{
			var pattern:RegExp =/^(\w+:|\\|\/)/;
			if (path.length == 0 || pattern.test(path)) {
				return path;
			} else {
				return xmlPathName + path;
			}
		}
		
		/**
		 * 映像定義ファイル読み込み完了時処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function processMovieDesc(event:Event):void
		{
			var i:int;
			var j:int;
			var index:int;
			var index2:int;
			
			loader.removeEventListener(Event.COMPLETE, processMovieDesc);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
			//読み込んだ内容を元に，XMLデータを作成
			var xmlobj:XML = new XML(event.target.data);

			mcShutter.tSetupReport.text = "初期化中です";

			//戻り先URL取得
			if (xmlobj.hasOwnProperty("returnUrl")) {
				var urlStr:String = relativePathFromXML(xmlobj.returnUrl.toString());
				if (UtilFuncs.checkProtocol(urlStr)) {
					returnUrl = urlStr;
				}
			}
			//映像ファイル情報取得
			if (xmlobj.hasOwnProperty("movieFiles")) {
				for (i = 0; i < xmlobj.movieFiles.item.length(); ++i) {
					if (xmlobj.movieFiles.item[i].hasOwnProperty("@id")) {
						index = xmlobj.movieFiles.item[i].@id;
					} else {
						index = i;
					}
					if (xmlobj.movieFiles.item[i].hasOwnProperty("path")) {
						movieFileName[index] = relativePathFromXML(xmlobj.movieFiles.item[i].path.toString());
					}
					if (xmlobj.movieFiles.item[i].hasOwnProperty("effectFiles")) {
						//エフェクトファイル情報取得
						for (j=0; j < xmlobj.movieFiles.item[i].effectFiles.item.length(); ++j) {
							if (xmlobj.movieFiles.item[i].effectFiles.item[j].hasOwnProperty("@id")) {
								index2 = xmlobj.movieFiles.item[i].effectFiles.item[j].@id;
							} else {
								index2 = j;
							}
							if (xmlobj.movieFiles.item[i].effectFiles.item[j].hasOwnProperty("path")) {
								effectFileName[index][index2] = relativePathFromXML(xmlobj.movieFiles.item[i].effectFiles.item[j].path.toString());
							}
						}
					}
				}
				
			}
			//字幕ファイル情報取得
			if (xmlobj.hasOwnProperty("captionFiles")) {
				for (i=0; i < xmlobj.captionFiles.item.length(); ++i) {
					if (xmlobj.captionFiles.item[i].hasOwnProperty("@id")) {
						index = xmlobj.captionFiles.item[i].@id;
					} else {
						index = i;
					}
					if (xmlobj.captionFiles.item[i].hasOwnProperty("path")) {
						captionFileName[index] = relativePathFromXML(xmlobj.captionFiles.item[i].path.toString());
					}
				}
			}
			//しおりファイル情報取得
			if (xmlobj.hasOwnProperty("bookmarkListFiles")) {
				for (i=0; i < xmlobj.bookmarkListFiles.item.length(); ++i) {
					if (xmlobj.bookmarkListFiles.item[i].hasOwnProperty("path")) {
						bookmarkListFileName.push(relativePathFromXML(xmlobj.bookmarkListFiles.item[i].path.toString()));
					}
				}
			}
			//しおりクリッカブルマップファイル情報取得
			if (xmlobj.hasOwnProperty("bookmarkMapFiles")) {
				for (i=0; i < xmlobj.bookmarkMapFiles.item.length(); ++i) {
					if (xmlobj.bookmarkMapFiles.item[i].hasOwnProperty("path")) {
						bookmarkMapFileName.push(relativePathFromXML(xmlobj.bookmarkMapFiles.item[i].path.toString()));
					}
				}
			}
			//再生時間取得
			if (xmlobj.hasOwnProperty("movieLength")) {
				if (xmlobj.movieLength.hasOwnProperty("seconds")) {
					movieLength = UtilFuncs.StringToNumber(xmlobj.movieLength.seconds.toString());
				} else if (xmlobj.movieLength.hasOwnProperty("hmsValue")) {
					movieLength = UtilFuncs.HMSToSecond(xmlobj.movieLength.hmsValue.toString());
				}
			}
			//タイトル取得
			if (xmlobj.hasOwnProperty("title")) {
				dispFilename.appendText(" : " + xmlobj.title.toString());
			}
			startReadEffect();
		}
		
		/**
		 * エフェクトファイル読み込み開始.
		 */
		private function startReadEffect():void
		{
			mcShutter.tSetupReport.appendText("\nエフェクトの読み込み開始");
			movieIdx = 0;
			effectIdx = 0;
			for (movieIdx = 0; movieIdx < MOVIE_NUM; ++movieIdx) {
				for (effectIdx = 0; effectIdx < EFFECT_NUM; ++effectIdx) {
					if (effectFileName[movieIdx][effectIdx] != "") {
						loader = new URLLoader();
						request = new URLRequest(effectFileName[movieIdx][effectIdx]);
						loader.addEventListener(Event.COMPLETE, processEffectDesc);
						loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
						loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
						loader.load(request);
						return;
					}
				}
			}
			//ファイルが全く無い場合のみここに来る
			effectControler.setup(effectArray, effSwInitialState, mc_player.mcEffectScreen, mc_player.player);
			startReadCaption();
		}
		
		/**
		 * エフェクト画像読み込み完了時処理.
		 * 
		 * <p>読み込んだ画像の中央を原点に設定する。</p>
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function imgLoadCompleteHandler(event:Event):void
		{
			var ldr:Loader = event.currentTarget.loader as Loader;
			ldr.removeEventListener(Event.COMPLETE, imgLoadCompleteHandler);
			ldr.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
			ldr.x = -ldr.content.width / 2;
			ldr.y = -ldr.content.height / 2;
		}
		
		/**
		 * エフェクトファイル読み込み処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function processEffectDesc(event:Event):void
		{
			var i:int;
			var j:int;
			var index:int;
			var index2:int;
			var strEffType:String;
			var imgloader:Loader;
			
			loader.removeEventListener(Event.COMPLETE, processEffectDesc);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
			//読み込んだ内容を元に，XMLデータを作成
			var xmlobj:XML = new XML(event.target.data);
			
			if (xmlobj.hasOwnProperty("label")) {
				effLabel[movieIdx][effectIdx] = xmlobj.label.toString();
			}
			if (xmlobj.hasOwnProperty("initialVisible")) {
				effSwInitialState[movieIdx][effectIdx] = UtilFuncs.strToBoolean(xmlobj.initialVisible.toString());
			}
			for (i = 0; i < xmlobj.item.length(); ++i) {
				effectArray[movieIdx][effectIdx].push(new EffectItem());
				with (effectArray[movieIdx][effectIdx][i]) {
					if (xmlobj.item[i].hasOwnProperty("id")) {
						id = xmlobj.item[i].id.toString();
					}
					if (xmlobj.item[i].hasOwnProperty("type")) {
						strEffType = xmlobj.item[i].type.toString();
					}
					if (xmlobj.item[i].(hasOwnProperty("image") && image.hasOwnProperty("path"))) {
						imagepath = relativePathFromXML(xmlobj.item[i].image.path.toString());
					}
					//エフェクトのインスタンス生成
					if (strEffType == EFFECT_TYPE_ARROW) {
						efftype = EffectControl.EFFECT_TYPE_ARROW;
						effectSymbol = new eff_arrow();
					} else if (strEffType == EFFECT_TYPE_CIRCLE) {
						efftype = EffectControl.EFFECT_TYPE_CIRCLE;
						effectSymbol = new eff_circle();
					} else if (strEffType == EFFECT_TYPE_IMG) {
						efftype = EffectControl.EFFECT_TYPE_IMG;
						imgloader = new Loader();
						effectSymbol = new MovieClip();
						effectSymbol.addChild(imgloader);
						imgloader.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoadCompleteHandler);
						imgloader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
						imgloader.load(new URLRequest(imagepath));
					}
					effectSymbol.originalHeight = effectSymbol.height;
					if (xmlobj.item[i].hasOwnProperty("cues")) {
						for (j = 0; j < xmlobj.item[i].cues.item.length(); ++j) {
							cueArr.push(new CueItem());
							if (xmlobj.item[i].cues.item[j].hasOwnProperty("time")) {
								if (xmlobj.item[i].cues.item[j].time.hasOwnProperty("seconds")) {
									cueArr[j].time = UtilFuncs.StringToNumber(xmlobj.item[i].cues.item[j].time.seconds.toString());
								} else if (xmlobj.item[i].cues.item[j].time.hasOwnProperty("hmsValue")) {
									cueArr[j].time = UtilFuncs.HMSToSecond(xmlobj.item[i].cues.item[j].time.hmsValue.toString());
								}
							}
							if (xmlobj.item[i].cues.item[j].hasOwnProperty("pos")) {
								if (xmlobj.item[i].cues.item[j].pos.hasOwnProperty("x")) {
									cueArr[j].x = UtilFuncs.StringToNumber(xmlobj.item[i].cues.item[j].pos.x.toString());
								}
								if (xmlobj.item[i].cues.item[j].pos.hasOwnProperty("y")) {
									cueArr[j].y = UtilFuncs.StringToNumber(xmlobj.item[i].cues.item[j].pos.y.toString());
								}
							}
							if (xmlobj.item[i].cues.item[j].(hasOwnProperty("angle") && angle.hasOwnProperty("degree"))) {
								cueArr[j].angle = UtilFuncs.StringToNumber(xmlobj.item[i].cues.item[j].angle.degree.toString());
							}
							if (xmlobj.item[i].cues.item[j].hasOwnProperty("scale")) {
								if (xmlobj.item[i].cues.item[j].scale.hasOwnProperty("x")) {
									cueArr[j].scaleX = UtilFuncs.StringToNumber(xmlobj.item[i].cues.item[j].scale.x.toString());
								}
								if (xmlobj.item[i].cues.item[j].scale.hasOwnProperty("y")) {
									cueArr[j].scaleY = UtilFuncs.StringToNumber(xmlobj.item[i].cues.item[j].scale.y.toString());
								}
							}
							if (sttime == 0) {
								sttime = cueArr[j].time;
							}
							if (edtime < cueArr[j].time) {
								edtime = cueArr[j].time;
							}
						}
					}
				}
			}
			
			//次のファイルの読み出し開始
			++effectIdx;
			while (movieIdx < MOVIE_NUM) {
				while (effectIdx < EFFECT_NUM) {
					if (effectFileName[movieIdx][effectIdx] != "") {
						loader = new URLLoader();
						request = new URLRequest(effectFileName[movieIdx][effectIdx]);
						loader.addEventListener(Event.COMPLETE, processEffectDesc);
						loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
						loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
						loader.load(request);
						return;
					} else {
						++effectIdx;
					}
				}
				effectIdx = 0;
				++movieIdx;
			}
			
			//最後のファイルの場合だけここに来る
			effectControler.setup(effectArray, effSwInitialState, mc_player.mcEffectScreen, mc_player.player);
			startReadCaption();
		}
		
		/**
		 * 字幕ファイル読み込み開始.
		 */
		private function startReadCaption():void
		{
			mcShutter.tSetupReport.appendText("\n字幕の読み込み開始");
			for (captionIdx = 0; captionIdx < CAPTION_NUM; ++captionIdx) {
				if (captionFileName[captionIdx] != "") {
					loader = new URLLoader();
					request = new URLRequest(captionFileName[captionIdx]);
					loader.addEventListener(Event.COMPLETE, processCaptionDesc);
					loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
					loader.load(request);
					return;
				}
			}
			//ファイルが全く無い場合のみここに来る
			startReadBookmarkList();
		}

		/**
		 * 字幕ファイル読み込み処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function processCaptionDesc(event:Event):void
		{
			var i:int;
			var wknum:Number;
			
			loader.removeEventListener(Event.COMPLETE, processCaptionDesc);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
			//読み込んだ内容を元に，XMLデータを作成
			var xmlobj:XML = new XML(event.target.data);
			
			for (i = 0; i < xmlobj.item.length(); ++i) {
				captionArray[captionIdx].push(new CaptionItem());
				with (captionArray[captionIdx][i]) {
					if (xmlobj.item[i].hasOwnProperty("id")) {
						id = xmlobj.item[i].id.toString();
					}
					if (xmlobj.item[i].hasOwnProperty("text")) {
						captionText = xmlobj.item[i].text.toString();
					}
					if (xmlobj.item[i].hasOwnProperty("startTime")) {
						if (xmlobj.item[i].startTime.hasOwnProperty("seconds")) {
							sttime = UtilFuncs.StringToNumber(xmlobj.item[i].startTime.seconds.toString());
						} else if (xmlobj.item[i].startTime.hasOwnProperty("hmsValue")) {
							sttime = UtilFuncs.HMSToSecond(xmlobj.item[i].startTime.hmsValue.toString());
						}
					}
					if (xmlobj.item[i].hasOwnProperty("endTime")) {
						if (xmlobj.item[i].endTime.hasOwnProperty("seconds")) {
							edtime = UtilFuncs.StringToNumber(xmlobj.item[i].endTime.seconds.toString());
						} else if (xmlobj.item[i].endTime.hasOwnProperty("hmsValue")) {
							edtime = UtilFuncs.HMSToSecond(xmlobj.item[i].endTime.hmsValue.toString());
						}
					}
					if (edtime < sttime) {
						wknum = edtime;
						edtime = sttime;
						sttime = wknum;
					}
					if (xmlobj.item[i].hasOwnProperty("font")) {
						if (xmlobj.item[i].font.hasOwnProperty("size")) {
							fontSize = UtilFuncs.StringToNumber(xmlobj.item[i].font.size.toString());
						}
					}
				}
			}
			mc_Caption.setCaptionData(captionIdx, captionArray[captionIdx]);
			
			//次のファイルの読み出し開始
			++captionIdx;
			while (captionIdx < CAPTION_NUM) {
				if (captionFileName[captionIdx] != "") {
					loader = new URLLoader();
					request = new URLRequest(captionFileName[captionIdx]);
					loader.addEventListener(Event.COMPLETE, processCaptionDesc);
					loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
					loader.load(request);
					return;
				}
				++captionIdx;
			}
			//最後のファイルの場合だけここに来る
			startReadBookmarkList();
		}

		/**
		 * しおりリスト読み込み開始.
		 */
		private function startReadBookmarkList():void
		{
			mcShutter.tSetupReport.appendText("\nしおりリストの読み込み開始");
			bookmarkIdx = 0;
			for (bookmarkListIdx = 0; bookmarkListIdx < bookmarkListFileName.length; ++bookmarkListIdx) {
				if (bookmarkListFileName[bookmarkListIdx] != "") {
					loader = new URLLoader();
					request = new URLRequest(bookmarkListFileName[bookmarkListIdx]);
					loader.addEventListener(Event.COMPLETE, processBookmarkList);
					loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
					loader.load(request);
					return;
				}
			}
			//ファイルが全く無い場合のみここに来る
			startReadBookmarkMap();
		}

		/**
		 * 再生範囲を設定する
		 * @param	sttime	開始時刻
		 * @param	edtime	終了時刻
		 */
		public function setPlayRange(sttime:Number, edtime:Number):void
		{
			if (sttime < mc_player.playRangeEnd) {
				mc_player.playRangeStart = sttime;
				mc_player.playRangeEnd = edtime;
			} else {
				mc_player.playRangeEnd = edtime;
				mc_player.playRangeStart = sttime;
			}
		}
		
		/**
		 * しおり選択処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function bookmarkSelectHandler(event:Event):void
		{
			var list:List = event.target as List;
			var btn:TransparentButton = event.target as TransparentButton;
			var bkmkdata:BookmarkItem;
			if (list != null) {
				// しおりリストがクリックされた場合
				if (list.selectedItem != null) {
					bkmkdata = list.selectedItem.data;
				}
			} else if (btn != null) {
				// しおりクリッカブルマップがクリックされた場合
				bkmkdata = btn.bkmk;
			}
			if (bkmkdata != null) {
				setPlayRange(bkmkdata.sttime, bkmkdata.edtime);
				if (bkmkdata == mcBookmarkPane.selectedBookmark) {
					//選択中のしおりが再度クリックされたら頭出し
					headHandler(null);
				} else if (mc_player.playheadTime < bkmkdata.sttime || mc_player.playheadTime > bkmkdata.edtime) {
					if (mcPlayerControl.bPause.visible) {
						pauseHandler(null);
					}
					//mc_player.pauseVideo();
					mc_player.seekVideo(bkmkdata.sttime);
				}
			}
			mcBookmarkPane.selectionUpdated(true);
			mcBookmarkPane.selectedBookmark = bkmkdata;
		}
		
		/**
		 * 範囲選択スライダドラッグ時にしおりを無効化する
		 */
		public function bookmarkInvalidated():void
		{
			mcBookmarkPane.selectionUpdated(false);
		}
		
		/**
		 * しおり選択解除ボタン処理
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function cancelBookmarkHandler(event:MouseEvent):void
		{
			mc_player.playRangeStart = 0;
			mc_player.playRangeEnd = movieLength;
			mcBookmarkPane.cancelBookmarkSelection();
		}
		
		/**
		 * しおりリスト読み込み処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function processBookmarkList(event:Event):void
		{
			var i:int;
			var itemlabel:String;
			var bkmkdata:BookmarkItem;
			
			loader.removeEventListener(Event.COMPLETE, processBookmarkList);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
			//読み込んだ内容を元に，XMLデータを作成
			var xmlobj:XML = new XML(event.target.data);
			var listno:int = mcBookmarkPane.addList(bookmarkSelectHandler);
			
			for (i = 0; i < xmlobj.item.length(); ++i) {
				bkmkdata = new BookmarkItem();
				itemlabel = "";
				if (xmlobj.item[i].hasOwnProperty("startTime")) {
					if (xmlobj.item[i].startTime.hasOwnProperty("seconds")) {
						bkmkdata.sttime = UtilFuncs.StringToNumber(xmlobj.item[i].startTime.seconds.toString());
					} else if (xmlobj.item[i].startTime.hasOwnProperty("hmsValue")) {
						bkmkdata.sttime = UtilFuncs.HMSToSecond(xmlobj.item[i].startTime.hmsValue.toString());
					}
				}
				if (xmlobj.item[i].hasOwnProperty("endTime")) {
					if (xmlobj.item[i].endTime.hasOwnProperty("seconds")) {
						bkmkdata.edtime = UtilFuncs.StringToNumber(xmlobj.item[i].endTime.seconds.toString());
					} else if (xmlobj.item[i].endTime.hasOwnProperty("hmsValue")) {
						bkmkdata.edtime = UtilFuncs.HMSToSecond(xmlobj.item[i].endTime.hmsValue.toString());
					}
				}
				if (xmlobj.item[i].hasOwnProperty("text")) {
					itemlabel = xmlobj.item[i].text.toString();
				}
				if (xmlobj.item[i].hasOwnProperty("favorite")) {
					bkmkdata.isFav = UtilFuncs.strToBoolean(xmlobj.item[i].favorite.toString());
				}
				bkmkdata.id = ("000" + i.toString()).substr( -3);
				mcBookmarkPane.addBookmarkToList(listno, itemlabel, bkmkdata);
			}
			
			//次のファイルの読み出し開始
			++bookmarkIdx;
			++bookmarkListIdx;
			while (bookmarkListIdx < bookmarkListFileName.length) {
				if (bookmarkListFileName[bookmarkListIdx] != "") {
					loader = new URLLoader();
					request = new URLRequest(bookmarkListFileName[bookmarkListIdx]);
					loader.addEventListener(Event.COMPLETE, processBookmarkList);
					loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
					loader.load(request);
					return;
				}
				++bookmarkListIdx;
			}
			//最後のファイルの場合だけここに来る
			startReadBookmarkMap();
		}

		/**
		 * しおりクリッカブルマップ読み込み開始
		 */
		private function startReadBookmarkMap():void
		{
			mcShutter.tSetupReport.appendText("\nしおりクリッカブルマップの読み込み開始");
			for (bookmarkMapIdx = 0; bookmarkMapIdx < bookmarkMapFileName.length; ++bookmarkMapIdx) {
				if (bookmarkMapFileName[bookmarkMapIdx] != "") {
					loader = new URLLoader();
					request = new URLRequest(bookmarkMapFileName[bookmarkMapIdx]);
					loader.addEventListener(Event.COMPLETE, processBookmarkMap);
					loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
					loader.load(request);
					return;
				}
			}
			//ファイルが全く無い場合のみここに来る
			setMovie();
		}
		
		/**
		 * しおりクリッカブルマップ読み込み処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function processBookmarkMap(event:Event):void
		{
			var i:int;
			var bkmkdata:BookmarkItem;
			var x1:Number;
			var x2:Number;
			var y1:Number;
			var y2:Number;
			var maparea: TransparentButton;
			var imagesource:String = "";
			
			loader.removeEventListener(Event.COMPLETE, processBookmarkMap);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
			//読み込んだ内容を元に，XMLデータを作成
			var xmlobj:XML = new XML(event.target.data);
			
			//pane = new ScrollPane();
			if (xmlobj.(hasOwnProperty("image") && image.hasOwnProperty("path"))) {
				imagesource = relativePathFromXML(xmlobj.image.path.toString());
			}
			var mapno:int = mcBookmarkPane.addClickableMap(imagesource);
			
			for (i = 0; i < xmlobj.item.length(); ++i) {
				bkmkdata = new BookmarkItem();
				maparea = new TransparentButton();
				x1 = 0;
				y1 = 0;
				x2 = 0;
				y2 = 0;
				if (xmlobj.item[i].hasOwnProperty("startTime")) {
					if (xmlobj.item[i].startTime.hasOwnProperty("seconds")) {
						bkmkdata.sttime = UtilFuncs.StringToNumber(xmlobj.item[i].startTime.seconds.toString());
					} else if (xmlobj.item[i].startTime.hasOwnProperty("hmsValue")) {
						bkmkdata.sttime = UtilFuncs.HMSToSecond(xmlobj.item[i].startTime.hmsValue.toString());
					}
				}
				if (xmlobj.item[i].hasOwnProperty("endTime")) {
					if (xmlobj.item[i].endTime.hasOwnProperty("seconds")) {
						bkmkdata.edtime = UtilFuncs.StringToNumber(xmlobj.item[i].endTime.seconds.toString());
					} else if (xmlobj.item[i].endTime.hasOwnProperty("hmsValue")) {
						bkmkdata.edtime = UtilFuncs.HMSToSecond(xmlobj.item[i].endTime.hmsValue.toString());
					}
				}
				if (xmlobj.item[i].hasOwnProperty("area")) {
					if (xmlobj.item[i].area.hasOwnProperty("x1")) {
						x1 = UtilFuncs.StringToNumber(xmlobj.item[i].area.x1.toString());
					}
					if (xmlobj.item[i].area.hasOwnProperty("y1")) {
						y1 = UtilFuncs.StringToNumber(xmlobj.item[i].area.y1.toString());
					}
					if (xmlobj.item[i].area.hasOwnProperty("x2")) {
						x2 = UtilFuncs.StringToNumber(xmlobj.item[i].area.x2.toString());
					}
					if (xmlobj.item[i].area.hasOwnProperty("y2")) {
						y2 = UtilFuncs.StringToNumber(xmlobj.item[i].area.y2.toString());
					}
				}
				maparea.setup(x1, y1, x2, y2, bkmkdata);
				maparea.addEventListener(MouseEvent.CLICK, bookmarkSelectHandler);
				mcBookmarkPane.addBookmarkToMap(mapno, maparea);
			}
			
			//次のファイルの読み出し開始
			++bookmarkIdx;
			++bookmarkMapIdx;
			while (bookmarkMapIdx < bookmarkMapFileName.length) {
				if (bookmarkMapFileName[bookmarkMapIdx] != "") {
					loader = new URLLoader();
					request = new URLRequest(bookmarkMapFileName[bookmarkMapIdx]);
					loader.addEventListener(Event.COMPLETE, processBookmarkMap);
					loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
					loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
					loader.load(request);
					return;
				}
				++bookmarkMapIdx;
			}
			//最後のファイルの場合だけここに来る
			setMovie();
		}

		/**
		 * 動画へのアクセス開始
		 */
		private function setMovie():void
		{
			mcShutter.tSetupReport.appendText("\nムービーの準備中です");
			movieIdx = 0;
			mc_player.player.addEventListener(VideoEvent.READY, setMovie3);
			mc_player.videoSource = movieFileName[movieIdx];
		}

		/**
		 * READYイベントハンドラ.
		 * 
		 * <p>ムービー1つアクセスする毎にREADYを待つ。</p>
		 * 
		 * @param	eventObject	イベントオブジェクト
		 */
		public function setMovie2(eventObject:VideoEvent):void
		{
			mcPlayerControl.mc_seekBar.totalPlaytime = mc_player.player.totalTime;
			mcPopupPlayerControl.mc_seekBar.totalPlaytime = mc_player.player.totalTime;
			movieReadyChk[movieIdx] = 1;
			++movieIdx;
			while ((movieIdx < MOVIE_NUM) && (movieFileName[movieIdx] == "")) {
				++movieIdx;
			}
			if (movieIdx >= MOVIE_NUM) {
				mc_player.player.removeEventListener(VideoEvent.READY, setMovie2);
				endSetup();
				return;
			}
			mc_player.player.activeVideoPlayerIndex = movieIdx; 
			//trace ("movieFileName[",movieIdx,"] fname:",movieFileName[movieIdx]);
			mc_player.videoSource = movieFileName[movieIdx];
		}

		/**
		 * READYイベントハンドラ.
		 * 
		 * <p>2つめ以降のムービーはREADYを待たずに次の処理へ進む。</p>
		 * 
		 * @param	eventObject	イベントオブジェクト
		 */
		public function setMovie3(eventObject:VideoEvent):void
		{
			mc_player.player.removeEventListener(VideoEvent.READY, setMovie3);
			mcPlayerControl.mc_seekBar.totalPlaytime = movieLength;
			mcPopupPlayerControl.mc_seekBar.totalPlaytime = movieLength;
			movieReadyChk[movieIdx] = 1;
			++movieIdx;
			while (movieIdx < MOVIE_NUM) {
				if (movieFileName[movieIdx] != "") {
					mc_player.player.activeVideoPlayerIndex = movieIdx; 
					//trace ("movieFileName[",movieIdx,"] fname:",movieFileName[movieIdx]);
					mc_player.videoSource = movieFileName[movieIdx];
				}
				++movieIdx;
			}
			endSetup();
		}

		/**
		 * 文字列を秒数に変換する
		 * @param	str
		 * @return
		 */
		public function getsec(str:String): Number
		{
			var num: Number;
			num = UtilFuncs.HMSToSecond(str, NaN);
			if (isNaN(num)) {
				num = Number(str);
			}

			if (isNaN(num)) {
				return -1;
			} else {
				return num;
			}
		}
		
		/**
		 * javascriptから呼び出してしおりをセット
		 * @param	sttime_str	再生開始時刻
		 * @param	edtime_str	再生終了時刻
		 */
		private function setRangeCallback(sttime_str:String, edtime_str:String) {
			var sttime:Number = getsec(sttime_str);
			var edtime:Number = getsec(edtime_str);
			if (sttime >= 0 && edtime >= 0) {
				if (sttime > edtime) {
					(function() {
						var tmp:Number = sttime;
						sttime = edtime;
						edtime = tmp;
					})();
				}
				setPlayRange(sttime, edtime);
				if (mc_player.playheadTime < sttime || mc_player.playheadTime > edtime) {
					if (mcPlayerControl.bPause.visible) {
						pauseHandler(null);
					}
					mc_player.seekVideo(sttime);
				}				
			}
		}
		
		/**
		 * 初期設定の最終処理.
		 */
		public function endSetup():void
		{
			mc_player.player.activeVideoPlayerIndex = 0; 
			chngVideo(0);
			mc_Caption.updateCaption(0, true);
			this.addEventListener(Event.ENTER_FRAME, enterframeHandler);
			mcShutter.visible = false;
			//リクエストパラメータで範囲指定されていた場合
			if (startTimeOnLoaded >= 0 && endTimeOnLoaded >= 0) {
				setPlayRange(startTimeOnLoaded, endTimeOnLoaded);
				mc_player.seekVideo(startTimeOnLoaded);
			}
			if (ExternalInterface.available && USE_JAVASCRIPT) {
				ExternalInterface.addCallback("setPlayRange", setRangeCallback);
			}
		}
		
		/**
		 * エフェクトの表示切り替えボタンの ON/OFF 状態変更時の処理.
		 * 
		 * @param	obj	プロパティ effno で対象エフェクトの番号を、プロパティ onoff で表示・非表示を指定。
		 */
		public function effectSW(obj:Object):void
		{
			var effno:int = obj.effno;
			var effsw:Boolean = obj.onoff;
			effectControler.setDispMode(selectedVideo, effno, effsw);
		}
		
		/**
		 * 映像切替完了後に実行する処理として <code>Player3Videos.setOnChangeVideoFunc()</code>に登録し、エフェクトと切替ボタンの表示状態を更新する.
		 * 
		 * @param	obj	切替先の映像番号
		 */
		public function chngVideoEffect(obj:Object):void
		{
			var no:int = int(obj);
			effectControler.swDisp(no,true);
			selectedVideo = no;
			for (var i:int = 0; i < effectButtonArray.length; ++i) {
				if (effectControler.getDispMode(no, i)) {
					effectButtonArray[i].setOn(true);
				} else {
					effectButtonArray[i].setOff(true);
				}
				effectButtonArray[i].label.text = effLabel[no][i];
			}
			
		}
		
		/**
		 * 映像切替ボタンの処理.
		 * 
		 * @param	obj	切替先の映像番号
		 */
		public function chngVideo(obj:Object):void
		{
			var no:int = int(obj);
			if (selectedVideo == no) return;
			mc_player.setOnChangeVideoFunc(chngVideoEffect, obj);
			mc_player.chngVideo(no);
		}
		
		/**
		 * 戻るボタン処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function bReturnHandler(event:MouseEvent):void
		{
			var request:URLRequest = new URLRequest(returnUrl);
			navigateToURL(request, "_self");
		}
		
		/**
		 * 表の表示処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function bMatrixHandler(event:MouseEvent):void
		{
			var request:URLRequest = new URLRequest(xmlPathName + "../" + MATRIX_HTML_FILE_NAME);
			navigateToURL(request, MATRIX_HTML_TARGET);
		}
		
		/**
		 * 頭出しボタン処理.
		 * 
		 * @param	obj	未使用
		 */
		public function headHandler(obj:Object):void
		{
			mc_player.seekVideo(mc_player.playRangeStart);
			mcPlayerControl.bHead.buttonEnabled = false;
		}
		
		/**
		 * フレーム戻しボタン処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function prevFrameHandler(event:MouseEvent):void
		{
			mc_player.stepFrame( -1);
		}
		
		/**
		 * 1秒戻しボタン処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function prevSecondHandler(event:MouseEvent):void
		{
			mc_player.stepSecond( -1);
		}
		
		/**
		 * 全区間選択時処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function allRangePlayHandler(event:MouseEvent):void
		{
			cancelBookmarkHandler(null);
		}
		
		/**
		 * Playボタン処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function playHandler(event:MouseEvent):void
		{
			if (mcPlayerControl.bSlow.isOn()) {
				mc_player.speedRangePlayVideo(0.5);
			} else {
				mc_player.speedRangePlayVideo();
			}
			mcPlayerControl.bPause.visible = true;
			mcPlayerControl.bPlay.visible = false;
			mcPopupPlayerControl.bPause.visible = true;
			mcPopupPlayerControl.bPlay.visible = false;
		}
		
		/**
		 * Pauseボタン処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function pauseHandler(event:MouseEvent):void
		{
			mc_player.pauseVideo();
			mcPlayerControl.bPause.visible = false;
			mcPlayerControl.bPlay.visible = true;
			mcPopupPlayerControl.bPause.visible = false;
			mcPopupPlayerControl.bPlay.visible = true;
		}
		
		/**
		 * スローモード切替処理.
		 * 
		 * @param	obj	プロパティ onoff でON/OFFを指定。
		 */
		public function slowSW(obj:Object):void
		{
			var sw:Boolean = obj.onoff;
			switch (mc_player.status) {
			case Player3Videos.MODE_FAST:
			case Player3Videos.MODE_SLOW:
			case Player3Videos.MODE_PLAY:
			case Player3Videos.MODE_RANGE:
			case Player3Videos.MODE_RANGE_FAST:
			case Player3Videos.MODE_RANGE_SLOW:
				if (sw) {
					mc_player.speedRangePlayVideo(0.5, -1, -1, false);
				} else {
					mc_player.speedRangePlayVideo(1, -1, -1, false);
				}
				break;
			case Player3Videos.MODE_RANGE_END:
			case Player3Videos.MODE_PAUSE:
				break;
			}
		}

		
		/**
		 * 1秒送りボタン処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function nextSecondHandler(event:MouseEvent):void
		{
			mc_player.stepSecond(1);
		}
		
		/**
		 * フレーム送りボタン処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function nextFrameHandler(event:MouseEvent):void
		{
			mc_player.stepFrame(1);
		}

		/**
		 * 繰り返し再生ON.
		 * 
		 * @param	obj	未使用
		 */
		public function repeatOnHandler(obj:Object):void
		{
			mc_player.rangeRepeat = true;
		}

		/**
		 * 繰り返し再生OFF.
		 * 
		 * @param	obj	未使用
		 */
		public function repeatOffHandler(obj:Object):void
		{
			mc_player.rangeRepeat = false;
		}
		
		/**
		 * 字幕の表示切り替えボタンの ON/OFF 状態変更時の処理.
		 * 
		 * @param	obj	プロパティ btnno で対象ボタンの番号を、プロパティ onoff で表示・非表示を指定。
		 */
		public function captionSW(obj:Object):void
		{
			var btnno:uint = obj.btnno;
			var sw:Boolean = obj.onoff;
			mc_Caption.captionDispSwSingle(btnno, sw);
			var now:Number = mc_player.player.playheadTime;
			mc_Caption.updateCaption(now, true);
		}
		
		/**
		 * フルスクリーン表示切り替えボタン処理
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function fullScreenBtnHandler(event:MouseEvent):void
		{
			setFullScreen();
		}
		
		/**
		 * 通常表示切り替えボタン処理
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function normalScreenBtnHandler(event:MouseEvent):void
		{
			endFullScreen();
		}
		
		/**
		 * フルスクリーンクリック処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function clickFullScreenHandler(event:MouseEvent):void
		{
			if (!mcPopupPlayerControl.visible) {
				mcPopupPlayerControl.alpha = POPUP_OVER_ALPHA;
				mcPopupPlayerControl.visible = true;
			} else {
				//フルスクリーン解除
				endFullScreen();
			}
		}
		
		/**
		 * ポップアップ操作パネルを綴じる
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function closePopupPlayerControl(event:MouseEvent):void
		{
			mcPopupPlayerControl.visible = false;
		}
		
		/**
		 * ポップアップ操作パネルマウスオーバー処理
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function popupOverHandler(event:MouseEvent):void
		{
			mcPopupPlayerControl.alpha = 1.0;
		}
		
		/**
		 * ポップアップ操作パネルマウスアウト処理
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function popupOutHandler(event:MouseEvent):void
		{
			mcPopupPlayerControl.alpha = POPUP_OVER_ALPHA;
		}
		
		/**
		 * 初期設定に戻るボタン処理
		 * 
		 * @param	event
		 */
		public function bResetHandler(event:MouseEvent):void
		{
			if (mcPlayerControl.bPause.visible) {
				mcPlayerControl.bPause.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			}
			if (mcPlayerControl.bSlow.isOn()) {
				mcPlayerControl.bSlow.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			}
			mcPlayerControl.bAllRange.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			mc_player.seekVideo(0);
			for (var mvidx:int = 0; mvidx < MOVIE_NUM; ++mvidx) {
				for (var effidx:int = 0; effidx < EFFECT_NUM; ++effidx) {
					effectControler.setDispMode(mvidx, effidx, effSwInitialState[mvidx][effidx]);
				}
			}
			chngVideoEffect(int(selectedVideo));
		}
		
		/**
		 * フレーム毎の処理.
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function enterframeHandler(event:Event):void
		{
			var now:Number = mc_player.player.playheadTime;
			mc_Caption.updateCaption(now);
			mcPlayerControl.mc_seekBar.updateView();
			mcPopupPlayerControl.mc_seekBar.updateView();
			effectControler.updateView(now);
			if (mc_player.status == Player3Videos.MODE_RANGE_END && mcPlayerControl.bPause.visible) {
				mcPlayerControl.bPause.visible = false;
				mcPlayerControl.bPlay.visible = true;
				mcPopupPlayerControl.bPause.visible = false;
				mcPopupPlayerControl.bPlay.visible = true;
			}
			if (!mcPlayerControl.mcVolumeControl.isDragging() && Math.abs(mc_player.player.volume - mcPlayerControl.mcVolumeControl.volume) > half_volume_step) {
				mcPlayerControl.mcVolumeControl.volume = mc_player.player.volume;
			}
			if (! mcPopupPlayerControl.mcVolumeControl.isDragging() && Math.abs(mc_player.player.volume - mcPopupPlayerControl.mcVolumeControl.volume) > half_volume_step) {
				mcPopupPlayerControl.mcVolumeControl.volume = mc_player.player.volume;
			}
			//if (mc_player.status != Player3Videos.MODE_PAUSE) {
			if (!mc_player.isSeeking) {
				if (Math.abs(mc_player.playheadTime-mcPlayerControl.mc_seekBar.playRangeStart) > mc_player.deemedKeyFramePitch) {
					mcPlayerControl.bHead.buttonEnabled = true;
				} else {
					mcPlayerControl.bHead.buttonEnabled = false;
				}
			}
		}
		
		/**
		 * フルスクリーン表示切り替え処理
		 */
		public function setFullScreen():void
		{
			mcPlayerControl.visible = false;
			mcUnderPopup.visible = true;
			mc_CaptionFull.visible = true;
			mc_Caption.dispTo = mc_CaptionFull;
			mc_Caption.updateCaption(mc_player.player.playheadTime, true);
			mc_player.x = player_full_x;
			mc_player.y = player_full_y;
			mc_player.scaleX = player_full_scale;
			mc_player.scaleY = player_full_scale;
			FullBG.visible = true;
			stage.displayState = "fullScreen";
		}
		
		/**
		 * 通常表示切替処理
		 */
		public function endFullScreen():void
		{
			stage.displayState = "normal";
			mcPlayerControl.visible = true;
			mcPopupPlayerControl.visible = false;
			mcUnderPopup.visible = false;
			mc_CaptionFull.visible = false;
			mc_Caption.dispTo = mc_Caption;
			mc_Caption.updateCaption(mc_player.player.playheadTime, true);
			mc_player.x = player_orig_x;
			mc_player.y = player_orig_y;
			mc_player.scaleX = 1;
			mc_player.scaleY = 1;
			FullBG.visible = false;
		}
		
		/**
		 * コンストラクタ.
		 * 
		 * <p>メンバの初期化を行い、映像記述XMLファイルの読み込みを開始する。</p>
		 */
		public function MovieViewer()
		{
			var flashVars:Object = loaderInfo.parameters;
			var i:int;
			var j:int;
			var btnparam:Object;
			var player_orig_width:Number;
			var player_orig_height:Number;
			var player_full_width:Number;
			var player_full_height:Number;
			var scale1:Number;
			var scale2:Number;
			
			stage.scaleMode = StageScaleMode.SHOW_ALL;
			FullBG.visible = false;
			
			player_orig_x = mc_player.x;
			player_orig_y = mc_player.y;
			player_orig_width = mc_player.width;
			player_orig_height = mc_player.height;
			
			player_full_x = 0;
			player_full_y = 0;
			player_full_width = stage.width;
			player_full_height = mc_CaptionFull.y;
			scale1 = player_full_width / player_orig_width;
			scale2 = player_full_height / player_orig_height;
			if (scale1 <= scale2) {
				player_full_scale = scale1;
				player_full_y = (mc_CaptionFull.y - player_orig_height * player_full_scale) / 2;
			} else {
				player_full_scale = scale2;
				player_full_x = (stage.width - player_orig_width * player_full_scale) / 2;
			}
			
			half_volume_step = 1.0 / mcPlayerControl.mcVolumeControl.volumeStepNumber / 2;
			
			//戻るボタンの設定
			bReturn.addEventListener(MouseEvent.CLICK, bReturnHandler);
			
			//表の表示ボタンの設定
			bMatrix.addEventListener(MouseEvent.CLICK, bMatrixHandler);
			
			//映像切替ボタンの設定
			selVideoBtnArr.push(0);
			btnVideo1.attachTo(selVideoBtnArr);
			btnVideo1.setOnFunc(chngVideo, int(0));
			btnVideo2.attachTo(selVideoBtnArr);
			btnVideo2.setOnFunc(chngVideo, int(1));
			btnVideo3.attachTo(selVideoBtnArr);
			btnVideo3.setOnFunc(chngVideo, int(2));
			
			//字幕ON/OFFボタンの設定
			capButtonArray = new Vector.<ToggleButtonBase>();
			capButtonArray.push(mc_Caption.bCap1);
			capButtonArray.push(mc_Caption.bCap2);
			for (i = 0; i < capButtonArray.length; ++i) {
				capButtonArray[i].setOff();
				btnparam = new Object();
				btnparam.btnno = i;
				btnparam.onoff = false;
				capButtonArray[i].setOffFunc(captionSW, btnparam);
				captionSW(btnparam);
				btnparam = new Object();
				btnparam.btnno = i;
				btnparam.onoff = true;
				capButtonArray[i].setOnFunc(captionSW, btnparam);
				capButtonArray[i].setOn();
			}
			
			//エフェクトON/OFFボタンの設定
			var effbtnparam:Object;
			effectButtonArray = new Vector.<LabeledToggleButton>();
			effectButtonArray.push(mcEffectButtons.btnA);
			effectButtonArray.push(mcEffectButtons.btnB);
			effectButtonArray.push(mcEffectButtons.btnC);
			effectButtonArray.push(mcEffectButtons.btnD);
			for (i = 0; i < effectButtonArray.length; ++i) {
				effectButtonArray[i].setOff();
				effbtnparam = new Object();
				effbtnparam.effno = i;
				effbtnparam.onoff = false;
				effectButtonArray[i].setOffFunc(effectSW, effbtnparam);
				effbtnparam = new Object();
				effbtnparam.effno = i;
				effbtnparam.onoff = true;
				effectButtonArray[i].setOnFunc(effectSW, effbtnparam);
			}
			
			//プレイヤー操作部の設定
			//SimpleButtonBaseから派生するボタンで、有効・無効を切り替えるものは、イベントリスナーでなくset～Funcで処理を設定すること
			mcPlayerControl.bHead.setClickFunc(headHandler, null);
			mcPlayerControl.bPrevF.addEventListener(MouseEvent.CLICK, prevFrameHandler);
			mcPlayerControl.bPrevS.addEventListener(MouseEvent.CLICK, prevSecondHandler);
			mcPlayerControl.bAllRange.addEventListener(MouseEvent.CLICK, allRangePlayHandler);
			mcPlayerControl.bPlay.addEventListener(MouseEvent.CLICK, playHandler);
			mcPlayerControl.bPause.addEventListener(MouseEvent.CLICK, pauseHandler);
			mcPlayerControl.bSlow.setOff();
			btnparam = new Object();
			btnparam.onoff = false;
			mcPlayerControl.bSlow.setOffFunc(slowSW, btnparam);
			btnparam = new Object();
			btnparam.onoff = true;
			mcPlayerControl.bSlow.setOnFunc(slowSW, btnparam);
			mcPlayerControl.bNextS.addEventListener(MouseEvent.CLICK, nextSecondHandler);
			mcPlayerControl.bNextF.addEventListener(MouseEvent.CLICK, nextFrameHandler);

			mcPlayerControl.bRepeatOnOff.setOnFunc(repeatOnHandler, null);
			mcPlayerControl.bRepeatOnOff.setOffFunc(repeatOffHandler, null);
			
			mcPlayerControl.mcVolumeControl.setTargetPlayer(mc_player.player);
			
			mcPlayerControl.mc_seekBar.setTargetPlayer(mc_player);
			mcPlayerControl.mc_seekBar.onDraggingRange = bookmarkInvalidated;
			
			mcPlayerControl.bFullScreen.addEventListener(MouseEvent.CLICK, fullScreenBtnHandler);

			mcPopupPlayerControl.bPlay.addEventListener(MouseEvent.CLICK, playHandler);
			mcPopupPlayerControl.bPause.addEventListener(MouseEvent.CLICK, pauseHandler);
			mcPopupPlayerControl.mcVolumeControl.setTargetPlayer(mc_player.player);
			mcPopupPlayerControl.mc_seekBar.setTargetPlayer(mc_player);
			mcPopupPlayerControl.bNormalScreen.addEventListener(MouseEvent.CLICK, normalScreenBtnHandler);
			mcPopupPlayerControl.bClose.addEventListener(MouseEvent.CLICK, closePopupPlayerControl);
			mcPopupPlayerControl.addEventListener(MouseEvent.MOUSE_OVER, popupOverHandler);
			mcPopupPlayerControl.addEventListener(MouseEvent.MOUSE_OUT, popupOutHandler);
			mcPopupPlayerControl.mc_seekBar.onDraggingRange = bookmarkInvalidated;
			
			mcUnderPopup.addEventListener(MouseEvent.CLICK, clickFullScreenHandler);
			
			mc_CaptionFull.visible = false;
			mcPopupPlayerControl.visible = false;
			mcUnderPopup.visible = false;
			
			//シーン情報表示部の処理
			mcBookmarkPane.bookmarkListHeader.bCancel.addEventListener(MouseEvent.CLICK, cancelBookmarkHandler);
			
			bReset.addEventListener(MouseEvent.CLICK, bResetHandler);
			
			//データ構造の初期化
			movieFileName = new Array(MOVIE_NUM);
			movieReadyChk = new Array(MOVIE_NUM);
			for (i=0; i< MOVIE_NUM; ++i) { 
				movieFileName[i] = "";
				movieReadyChk[i] = 0;
			}
			effectFileName = new Vector.<Vector.<String>>(MOVIE_NUM);
			effectArray = new Vector.<Vector.<Vector.<EffectItem>>>(MOVIE_NUM);
			effSwInitialState = new Vector.<Vector.<Boolean>>(MOVIE_NUM);
			effLabel = new Vector.<Vector.<String>>(MOVIE_NUM);
			for (i=0; i< MOVIE_NUM; ++i) { 
				effectFileName[i] = new Vector.<String>(EFFECT_NUM);
				effectArray[i] = new Vector.<Vector.<EffectItem>>(EFFECT_NUM);
				effSwInitialState[i] = new Vector.<Boolean>(EFFECT_NUM);
				effLabel[i] = new Vector.<String>(EFFECT_NUM);
				for (j = 0; j < EFFECT_NUM; ++j) {
					effectFileName[i][j] = "";
					effectArray[i][j] = new Vector.<EffectItem>();
					effSwInitialState[i][j] = false;
					effLabel[i][j] = "エフェクト　" + String("ABCDEFGHIJ").substr(j, 1);
				}
			}
			captionFileName = new Vector.<String>(CAPTION_NUM);
			captionArray = new Vector.<Vector.<CaptionItem>>(CAPTION_NUM);
			for (i=0; i< CAPTION_NUM; ++i) { 
				captionFileName[i] = "";
				captionArray[i] = new Vector.<CaptionItem>();
			}
			bookmarkListFileName = new Vector.<String>();
			bookmarkMapFileName = new Vector.<String>();

			// 映像定義XMLファイル名の取得
			//var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters[XML_FILE_VARNAME];
			//if (paramObj) {
			//	xmlName = paramObj.toString();
			//}
			//if (!xmlName) {
			//	xmlName = DEFAULT_XML_FILENAME;
			//}
			var paramObj:Object = LoaderInfo(this.root.loaderInfo).parameters;
			var param_str:String;
			for (var name_str:String in paramObj) {
				param_str = String(paramObj[name_str]);
				switch (name_str) {
					// 映像定義XMLファイル名
					case XML_FILE_VARNAME:
						xmlName = param_str;
						break;
					// 頭出し先頭
					case START_TIME_VARNAME:
						startTimeOnLoaded = getsec(param_str);
						break;
					// 頭出し終了
					case END_TIME_VARNAME:
						endTimeOnLoaded = getsec(param_str);
						break;
				}
			}
			if (!xmlName) {
				xmlName = DEFAULT_XML_FILENAME;
			}
			(function() {
				var slpos:int = xmlName.lastIndexOf("/");
				var bslpos:int = xmlName.lastIndexOf("\\");
				if (slpos >= 0 || bslpos >= 0) {
					//パス情報が付いている
					xmlPathName = xmlName.substring(0, ((slpos > bslpos) ? slpos : bslpos) + 1);
				} else {
					//ファイル名のみ
					xmlPathName = "";
				}
			})();
			if (startTimeOnLoaded >= 0 && endTimeOnLoaded >= 0 && startTimeOnLoaded > endTimeOnLoaded) {
				(function() {
					var wk:Number = startTimeOnLoaded;
					startTimeOnLoaded = endTimeOnLoaded;
					endTimeOnLoaded = wk;
				})();
			}
			dispFilename.text = xmlName;
			//映像定義XMLファイル読み込み開始
			loader = new URLLoader();
			request = new URLRequest(xmlName);
			loader.addEventListener(Event.COMPLETE, processMovieDesc);
			loader.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderErrorHandler);
			loader.load(request);
		}
	}
}
