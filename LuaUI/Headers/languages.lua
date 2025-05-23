local langs = {
	{ lang = 'en', flag = 'gb', name = 'English' },
	{ lang = 'ru', flag = 'ru', name = 'Русский' },
	{ lang = 'pl', flag = 'pl', name = 'Polski' },
	{ lang = 'zh_CN', flag = 'cn', name = '簡體中文' },
	{ lang = 'zh_TW', flag = 'tw', name = '繁體中文' },
	{ lang = 'it', flag = 'it', name = 'Italiano' },
	{ lang = 'fr', flag = 'fr', name = 'Français' },
	{ lang = 'de', flag = 'de', name = 'Deutsch' },
	{ lang = 'tr', flag = 'tr', name = 'Türkçe' },
	{ lang = 'uk_UA', flag = 'ua', name = 'Українська' },
	{ lang = 'sl', flag = 'si', name = 'Slovenščina' },
	{ lang = 'ja', flag = 'jp', name = '日本語' },
}

local flagByLang, langByFlag = {}, {}
for i = 1, #langs do
	local x = langs[i]
	flagByLang[x.lang] = x.flag
	langByFlag[x.flag] = x.lang
end

setmetatable(langByFlag, { __index = function()
	return 'en'
end})

return langs, flagByLang, langByFlag
	
