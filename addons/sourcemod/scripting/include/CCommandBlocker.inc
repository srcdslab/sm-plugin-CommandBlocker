#if defined _class_ccommandblocker_
  #endinput
#endif
#define _class_ccommandblocker_

#include <basic>

enum eBlockType
{
	eBlockType_Block = 0,
	eBlockType_Kick,
	eBlockType_Ban
}

methodmap CCommandBlocker < Basic
{
	public CCommandBlocker()
	{
		Basic myclass = new Basic();

		myclass.SetString("sCommand", "");
		myclass.SetInt("iBlockType", eBlockType_Block);

		return view_as<CCommandBlocker>(myclass);
	}

	public bool GetCommand(char[] buffer, int length)
	{
		return this.GetString("sCommand", buffer, length);
	}

	public void SetCommand(const char[] buffer)
	{
		this.SetString("sCommand", buffer);
	}

	property int iBlockType
	{
		public get()
		{
			return this.GetInt("iBlockType");
		}
		public set(int value)
		{
			this.SetInt("iBlockType", value);
		}
	}
}