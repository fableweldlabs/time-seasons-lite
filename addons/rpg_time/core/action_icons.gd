@tool
extends RefCounted
## Original Night & Bloom glyphs. SVG source stays inside the script for portable exports.
const SVG: Dictionary = {
 "clock-forward": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M17 3a9 9 0 1 0 4 13M17 3h5v5M12 7v5l3 2M17 3l5 5\"/></g></svg>",
 "resume": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M8 4l13 8L8 20z\" fill=\"#FFFFFF\" stroke=\"none\"/></g></svg>",
 "pause": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M7 4v16M17 4v16\" stroke-width=\"5\"/></g></svg>",
 "sleep": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M17 3A9 9 0 1 0 21 17 8 8 0 0 1 17 3z\"/><path d=\"M19 8h4M21 6v4\"/></g></svg>",
 "save": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 3h14l3 3v15H3V3h1zM7 3v7h10V3M7 21v-7h10v7\"/></g></svg>",
 "restore": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M3 10a9 9 0 1 1 1 8M3 4v6h6M12 7v5l3 2\"/></g></svg>",
 "spring": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M12 21v-9M12 16C3 16 3 7 3 7s9-1 9 9M12 12C12 3 21 3 21 3s1 9-9 9\"/></g></svg>",
 "summer": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><circle cx=\"12\" cy=\"12\" r=\"4\"/><path d=\"M12 1v3M12 20v3M1 12h3M20 12h3M4 4l2 2M18 18l2 2M4 20l2-2M18 6l2-2\"/></g></svg>",
 "autumn": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 21l13-13M7 18C1 6 12 3 21 3c0 10-3 20-14 15zM10 15h6M13 12V7\"/></g></svg>",
 "winter": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M12 2v20M3.3 7l17.4 10M3.3 17L20.7 7M9 4l3 3 3-3M9 20l3-3 3 3M4 10l4-1-1-4M20 14l-4 1 1 4M4 14l4 1-1 4M20 10l-4-1 1-4\"/></g></svg>",
 "next-season": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M5 7a9 9 0 0 1 15 2M20 3v6h-6M19 17a9 9 0 0 1-15-2M4 21v-6h6\"/><path d=\"M10 12h4M12 10v4\"/></g></svg>",
 "settings": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><g fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"1.8\" stroke-linecap=\"round\" stroke-linejoin=\"round\"><path d=\"M4 6h16M4 12h16M4 18h16\"/><circle cx=\"9\" cy=\"6\" r=\"2\" fill=\"white\"/><circle cx=\"16\" cy=\"12\" r=\"2\" fill=\"white\"/><circle cx=\"8\" cy=\"18\" r=\"2\" fill=\"white\"/></g></svg>"
}
static var _textures: Dictionary = {}
static func get_icon(action: StringName) -> Texture2D:
 if _textures.has(action): return _textures[action]
 if not SVG.has(String(action)): return null
 var bitmap := Image.new()
 if bitmap.load_svg_from_string(SVG[String(action)]) != OK: return null
 var texture := ImageTexture.create_from_image(bitmap)
 _textures[action] = texture
 return texture
