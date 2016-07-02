// Copyright (c) 2013 Kyoto University and DoGA
package 
{
	import fl.core.UIComponent;
	import flash.display.*;
	import flash.events.*;
	import RadioButtonBase;

	/**
	 * しおりリストヘッダ部ソート方法選択メニュー.
	 */
	public class SortTypeSelecter extends MovieClip
	{
		/** 記述順ソートボタン */
		public var sortByID: RadioButtonBase;
		/** 名前順ソートボタン */
		public var sortByName: RadioButtonBase;
		/** 重要度順ソートボタン */
		public var sortByFav: RadioButtonBase;

		/**
		 * コンストラクタ
		 */
		public function SortTypeSelecter()
		{
		}
	}
}
