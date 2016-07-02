// Copyright (c) 2013 Kyoto University and DoGA
package 
{
	import fl.core.UIComponent;
	import flash.display.*;
	import flash.events.*;
	import flash.text.TextField;
	import SortTypeSelecter;

	/**
	 * しおりリストヘッダ部.
	 */
	public class BookmarkListHeader extends MovieClip
	{
		/** ソート方法切り替えボタン */
		public var bSort:SimpleButtonBase;
		/** ソート方法選択リスト表示部 */
		public var sortTypeSelecter:SortTypeSelecter;
		/** ソート方法表示部 */
		public var dispSortType:MovieClip;
		/** 選択中のしおりを表示 */
		public var dispCurrentBookmarkName:TextField;
		/** しおり選択解除ボタン */
		public var bCancel:SimpleButtonBase;
		/**
		 * コンストラクタ
		 */
		public function BookmarkListHeader()
		{
		}
	}
}
