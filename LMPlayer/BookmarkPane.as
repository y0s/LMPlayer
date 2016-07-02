// Copyright (c) 2012 Kyoto University and DoGA
package 
{
	import fl.core.UIComponent;
	import fl.events.ListEvent;
	import flash.display.*;
	import flash.events.*;
	import fl.containers.ScrollPane;
	import fl.controls.List;
	import fl.data.DataProvider;
	import fl.managers.StyleManager; 
	import flash.text.TextFormat; 
	import flash.net.URLRequest;
	import bSelBkmk;
	import BookmarkItem;
	import TransparentButton;
	import CustomCellRenderer;
	import BookmarkListHeader;

	/**
	 * シーン情報表示部クラス.
	 * 
	 * <p>しおりリスト･しおりクリッカブルマップ表示部と、表示するしおりリスト･しおりクリッカブルマップを切り替える選択ボタン表示部よりなる。</p>
	 */
	public class BookmarkPane extends MovieClip
	{
		/** 前の切替ボタンを表示するボタン */
		public var bPrev:SimpleButton;
		/** 後ろの切替ボタンを表示するボタン */
		public var bNext:SimpleButton;
		/**
		 * <code>bPrev</code>, <code>bNext</code> のクリックで移動して切替ボタンの表示範囲を変化させる切替ボタン表示領域。
		 */
		public var selButtonPlace:MovieClip;
		/**
		 * 各しおりリスト･しおりクリッカブルマップを子として保持するしおりリスト・クリッカブルマップ表示領域。
		 */
		public var bookmarkPlace:MovieClip;
		/** 切り替えボタン表示領域のマスク */
		public var buttonMask:MovieClip;
		/** しおりリスト・クリッカブルマップ管理配列 */
		public var bookmarkMcArray:Vector.<UIComponent> = new Vector.<UIComponent>();
		/** しおりリストDataProvider管理配列 */
		public var bookmarkDpAray:Vector.<DataProvider> = new Vector.<DataProvider>();
		/** しおりリスト時に表示するヘッダ */
		public var bookmarkListHeader:BookmarkListHeader;
		
		/** 切り替えボタンのラジオボタン制御配列.
		 * 
		 * @see	RadioButtonBase
		 */
		protected var bookmarkBtnArr:Array = new Array();
		/** 生成済みしおりリスト･しおりクリッカブルマップの個数 */
		protected var bookmarkIdx:int = 0;
		/** 現在表示されているしおりリスト･しおりクリッカブルマップ */
		protected var currentBookmarkIdx:int = 0;
		/** 現在選択されているしおりを含むしおりリスト･しおりクリッカブルマップ */
		protected var selectedBookmarkIdx:int = -1;
		/** 選択中のしおりアイテム */
		protected var selectedListItem:Object = null;
		/** 選択が現在有効かどうか */
		protected var isSelectionValid:Boolean = false;
		/** スライダが動いて選択が無効になった時のセルの背景 */
		protected var invalidSkin:MovieClip = new CellRenderer_selectedInvalidSkin();
		/** 選択中のしおり(しおりリスト･しおりクリッカブルマップ共通) */
		protected var _selectedBookmark:BookmarkItem = null;
		
		/** しおり未選択時の表示文字列 */
		protected var noSelectStr:String = "未選択";
		/** クリッカブルマップから選択時の表示文字列 */
		protected var mapSelectStr:String = "マップより選択";
		
		/** リスト・クリッカブルマップ表示領域の幅 */
		protected static const BOOKMARK_PLACE_WIDTH:Number = 298;
		/** リスト・クリッカブルマップ表示領域の高さ */
		protected static const BOOKMARK_PLACE_HEIGHT:Number = 561;
		/** リストヘッダ部の高さ */
		protected static const LIST_HEADER_HEIGHT:Number = 69;
		/** リストの位置調整 */
		protected static const ADJUST_LIST_TOP:Number = -10;
		/** リストの行の高さ */
		protected static const LIST_ROW_HEIGHT:Number = 20;
		
		/** ソートの種類の数 */
		protected static const SORT_TYPE_COUNT:int = 3;
		/** その他の子オブジェクトの数 */
		protected static const NUM_CHILDREN_OTHER_THAN_SORT_TYPE:int = 2;
		/** ソート方法切り替えラジオボタン制御配列 */
		protected var sortTypeArr:Array = new Array();
		/** リストソート方法(記述順にソート) */
		protected static const SORT_BY_ID:int = 0;
		/** ソート方法表示部フレームラベル(記述順にソート) */
		protected static const L_SORT_BY_ID:String = "l_byID";
		/** リストソート方法(名前順にソート) */
		protected static const SORT_BY_NAME:int = 1;
		/** ソート方法表示部フレームラベル(名前順にソート) */
		protected static const L_SORT_BY_NAME:String = "l_byName";
		/** リストソート方法(重要度順にソート) */
		protected static const SORT_BY_FAV:int = 2;
		/** ソート方法表示部フレームラベル(重要度順にソート) */
		protected static const L_SORT_BY_FAV:String = "l_byFav";
		
		/**
		 * コンストラクタ
		 */
		public function BookmarkPane()
		{
			bookmarkBtnArr.push(0);
			selButtonPlace.x = buttonMask.x;
			selButtonPlace.mask = buttonMask;
			bPrev.addEventListener(MouseEvent.CLICK, prevButtonHandler);
			bNext.addEventListener(MouseEvent.CLICK, nextButtonHandler);
			
			bookmarkListHeader.dispSortType.stop();
			bookmarkListHeader.sortTypeSelecter.visible = false;
			bookmarkListHeader.visible = false;
			
			sortTypeArr.push(0);
			bookmarkListHeader.sortTypeSelecter.sortByID.attachTo(sortTypeArr);
			bookmarkListHeader.sortTypeSelecter.sortByID.setOnFunc(sortBookmarkList, SORT_BY_ID);
			bookmarkListHeader.sortTypeSelecter.sortByName.attachTo(sortTypeArr);
			bookmarkListHeader.sortTypeSelecter.sortByName.setOnFunc(sortBookmarkList, SORT_BY_NAME);
			bookmarkListHeader.sortTypeSelecter.sortByFav.attachTo(sortTypeArr);
			bookmarkListHeader.sortTypeSelecter.sortByFav.setOnFunc(sortBookmarkList, SORT_BY_FAV);
			bookmarkListHeader.bSort.addEventListener(MouseEvent.CLICK, sortButtonHandler);
		}
		
		/**
		 * 前の切替ボタンを表示
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function prevButtonHandler(event:MouseEvent):void
		{
			if (selButtonPlace.x < buttonMask.x) {
				selButtonPlace.x += bookmarkBtnArr[1].width;
				if (selButtonPlace.x > buttonMask.x) {
					selButtonPlace.x = buttonMask.x;
				}
			}
		}

		/**
		 * 後の切替ボタンを表示
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function nextButtonHandler(event:MouseEvent):void
		{
			if (selButtonPlace.x + selButtonPlace.width > buttonMask.x + buttonMask.width) {
				selButtonPlace.x -= bookmarkBtnArr[1].width;
			}
		}
		
		/**
		 * ソート方法の選択ボタンをクリック
		 * 
		 * @param	event	イベントオブジェクト
		 */
		public function sortButtonHandler(event:MouseEvent):void
		{
			bookmarkListHeader.sortTypeSelecter.visible = !bookmarkListHeader.sortTypeSelecter.visible;
		}
		
		/**
		 * しおりリストをソート
		 * 
		 * @param	howto	ソート方法
		 */
		public function sortBookmarkList(obj:Object):void
		{
			var howto:int = int(obj);
			switch(howto) {
			case SORT_BY_ID:
				bookmarkListHeader.dispSortType.gotoAndStop(L_SORT_BY_ID);
				//記述順ソート
				bookmarkDpAray[currentBookmarkIdx].sortOn("id");
				break;
			case SORT_BY_NAME:
				bookmarkListHeader.dispSortType.gotoAndStop(L_SORT_BY_NAME);
				//名前順ソート
				bookmarkDpAray[currentBookmarkIdx].sortOn("label");
				break;
			case SORT_BY_FAV:
				bookmarkListHeader.dispSortType.gotoAndStop(L_SORT_BY_FAV);
				//重要度順ソート
				bookmarkDpAray[currentBookmarkIdx].sortOn(["isfav", "id"], [Array.DESCENDING, null]);
				break;
			}
			bookmarkListHeader.sortTypeSelecter.visible = false;
		}
		
		/**
		 * リスト切替ボタンクリック時処理
		 * 
		 * @param	obj	関連付けられたオブジェクト
		 */
		public function selBtnOnFunc(obj:Object):void
		{
			var btnno:uint = obj.btnno;
			var list:List = bookmarkMcArray[btnno] as List;
			currentBookmarkIdx = btnno;
			if (list != null) {
				bookmarkListHeader.visible = true;
				if (currentBookmarkIdx != selectedBookmarkIdx) {
					list.clearSelection();
				}
			} else {
				bookmarkListHeader.visible = false;
			}
		}
		
		/**
		 * リスト自体の選択状態は維持したままで、しおりの有効・無効を切り替える
		 * 
		 * @param	select	true: 有効 / false: 無効
		 */
		public function selectionUpdated(select:Boolean):void
		{
			if (select) {
				selectedBookmarkIdx = currentBookmarkIdx;
			} else {
				_selectedBookmark = null;
			}
			var list:List = null;
			if (selectedBookmarkIdx >= 0) {
				list = bookmarkMcArray[selectedBookmarkIdx] as List;
			}
			if (list != null) {
				selectedListItem = list.selectedItem;
				if (select) {
					list.selectedItem.invalid = false;
					list.clearRendererStyle("selectedUpSkin");
					if (list.selectedIndex >= 0) {
						bookmarkListHeader.dispCurrentBookmarkName.text = list.selectedItem.label;
					}
				} else if (isSelectionValid && list.selectedIndex >= 0) {
					list.selectedItem.invalid = true;
					list.setRendererStyle("selectedUpSkin", invalidSkin);
				}
			} else {
				selectedListItem = null;
				if (select) {
					bookmarkListHeader.dispCurrentBookmarkName.text = mapSelectStr;
				}
			}
			isSelectionValid = select;
		}

		/**
		 * 選択中のしおり
		 */
		public function get selectedBookmark():BookmarkItem
		{
			return _selectedBookmark;
		}

		public function set selectedBookmark(value:BookmarkItem):void 
		{
			_selectedBookmark = value;
		}
		
		/**
		 * しおりをクリックした時の処理.
		 * 
		 * <p>選択状態のアイテムをクリックしても　Event.CHANGE　イベントは発生しないので、
		 * ListEvent.ITEM_CLICK　イベントを検出して、　Event.CHANGE　イベントを送出する。</p>
		 * 
		 * @param	e	イベントオブジェクト
		 */
		private function listItemClickHandler(e:ListEvent):void
		{
			var targetList:List = e.currentTarget as List;
			if (targetList != null && e.item == selectedListItem) {
				targetList.dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		/**
		 * しおり選択解除処理
		 */
		public function cancelBookmarkSelection():void
		{
			bookmarkListHeader.dispCurrentBookmarkName.text = noSelectStr;
			selectedListItem = null;
			_selectedBookmark = null;
			var list:List = null;
			if (selectedBookmarkIdx >= 0) {
				list = bookmarkMcArray[selectedBookmarkIdx] as List;
			}
			if (list != null) {
				list.clearSelection();
			}
		}
		
		/**
		 * しおりリストのラベル生成関数
		 * 
		 * @param	obj	リストのアイテム
		 * @return	ラベルに表示する文字列
		 */
		public function labelStrFunc(obj:Object):String
		{
			return obj.id + "　　" + obj.label;
		}
		
		/**
		 * 新規しおりリストを追加する。
		 * 
		 * @param	handler	クリック時に起動させる関数
		 * @return	追加したリストのインデックス
		 */
		public function addList(handler:Function):int
		{
			var list:List = new List();
			var btn:bSelBkmk = new bSelBkmk();
			var dp:DataProvider = new DataProvider();
			var btnparam:Object = new Object();
			list.iconField = "iconSource";
			list.labelFunction = labelStrFunc;
			list.dataProvider = dp;
			list.rowHeight = LIST_ROW_HEIGHT;
			list.setStyle("cellRenderer", CustomCellRenderer); 
			list.setSize(BOOKMARK_PLACE_WIDTH, BOOKMARK_PLACE_HEIGHT - LIST_HEADER_HEIGHT - ADJUST_LIST_TOP);
			list.move(0, LIST_HEADER_HEIGHT + ADJUST_LIST_TOP);
			bookmarkMcArray.push(list);
			bookmarkPlace.addChild(list);
			bookmarkDpAray.push(dp);
			list.addEventListener(Event.CHANGE, handler);
			list.addEventListener(ListEvent.ITEM_CLICK, listItemClickHandler);
			btn.x = btn.width * bookmarkIdx;
			btn.y = 0;
			btn.btnlabel.text = String.fromCharCode(String("A").charCodeAt(0) + (bookmarkIdx % 26));
			btn.setTarget(list);
			btnparam.btnno = bookmarkIdx;
			btn.setOnFunc(selBtnOnFunc, btnparam);
			selButtonPlace.addChild(btn);
			btn.attachTo(bookmarkBtnArr);
			if (btn.isOn()) {
				list.visible = true;
				bookmarkListHeader.visible = true;
			} else {
				list.visible = false;
			}
			return bookmarkIdx++;
		}
		
		/**
		 * リストにしおりを追加する。
		 * 
		 * @param	idx			追加先リストのインデックス
		 * @param	labelText	表示するラベル
		 * @param	data		アイテムに関連付けるデータ
		 */
		public function addBookmarkToList(idx:int, labelText:String, data:BookmarkItem):void
		{
			if ((idx < 0) || (idx >= bookmarkMcArray.length)) {
				return;
			}
			var list:List = bookmarkMcArray[idx] as List;
			var dp:DataProvider = bookmarkDpAray[idx];
			if (list != null) {
				dp.addItem( { label:labelText, data:data , id:data.id, isfav:data.isFav, iconSource:(data.isFav)?favStar:blankIcon } );
			}
		}
		
		/**
		 * マップ画像読み込み完了時にコールされ、マップ画像のサイズに合わせてスクロールペインの描画を更新する。
		 * 
		 * @param	event	イベントオブジェクト
		 */
		private function imgLoadCompleteHandler(event:Event):void
		{
			var ldr:Loader = event.currentTarget.loader as Loader;
			ldr.removeEventListener(Event.COMPLETE, imgLoadCompleteHandler);
			
			var pane:ScrollPane = null;
			var obj:DisplayObjectContainer = ldr;
			while ((pane == null) && (obj != root )) {
				obj = obj.parent;
				pane = obj as ScrollPane;
			}
			if (pane != null) {
				pane.update();
			}
		}

		/**
		 * 新規クリッカブルマップを追加する。
		 * 
		 * @param	imgsource	画像のURL
		 * @return	追加したクリッカブルマップのインデックス
		 */
		public function addClickableMap(imgsource:String):int
		{
			var pane:ScrollPane = new ScrollPane();
			var btn:bSelBkmk = new bSelBkmk();
			var dp:DataProvider = new DataProvider();
			var btnparam:Object = new Object();
			bookmarkDpAray.push(dp);
			var mc:MovieClip = new MovieClip();
			var imgloader:Loader = new Loader();
			mc.addChild(imgloader);
			imgloader.contentLoaderInfo.addEventListener(Event.COMPLETE, imgLoadCompleteHandler);
			imgloader.load(new URLRequest(imgsource));
			pane.source = mc;
			pane.setSize(BOOKMARK_PLACE_WIDTH, BOOKMARK_PLACE_HEIGHT);
			pane.move(0, 0);
			bookmarkMcArray.push(pane);
			bookmarkPlace.addChild(pane);
			btn.x = btn.width * bookmarkIdx;
			btn.y = 0;
			btn.btnlabel.text = String.fromCharCode(String("A").charCodeAt(0) + (bookmarkIdx % 26));
			btn.setTarget(pane);
			btnparam.btnno = bookmarkIdx;
			btn.setOnFunc(selBtnOnFunc, btnparam);
			selButtonPlace.addChild(btn);
			btn.attachTo(bookmarkBtnArr);
			if (btn.isOn()) {
				pane.visible = true;
				bookmarkListHeader.visible = false;
			} else {
				pane.visible = false;
			}
			return bookmarkIdx++;
		}
		
		/**
		 * クリッカブルマップへ領域を追加する。
		 * 
		 * @param	idx			追加先クリッカブルマップのインデックス
		 * @param	areadata	ヒット領域として設定するオブジェクト
		 */
		public function addBookmarkToMap(idx:int, areadata:TransparentButton):void
		{
			if ((idx < 0) || (idx >= bookmarkMcArray.length)) {
				return;
			}
			var pane:ScrollPane = bookmarkMcArray[idx] as ScrollPane;
			var dp:DataProvider = bookmarkDpAray[idx];
			if (pane != null) {
				pane.source.addChild(areadata);
				dp.addItem( { data:areadata } );
			}
		}
	}
}