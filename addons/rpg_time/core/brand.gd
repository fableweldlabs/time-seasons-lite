@tool
extends RefCounted
## Owner-approved FW identity. Geometry locked on 2026-10-18.
const SVG: Dictionary = {
 "primary": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"512\" height=\"512\" viewBox=\"0 0 512 512\"><g transform=\"translate(42 27) scale(4.1)\"><g transform=\"translate(0 0) scale(1)\" fill=\"none\" stroke-width=\"8\" stroke-linejoin=\"round\" stroke-linecap=\"butt\"><defs><clipPath id=\"cut0_0\"><path d=\"M-20 -20H130V57.609756L45 107.365854V102.975610L-20 64.926829Z\"/></clipPath></defs><g clip-path=\"url(#cut0_0)\"><path d=\"M61 98L74 64 85 84 94 32L53 8 12 32v60\" stroke=\"#26365D\"/><path d=\"M53.041 79.317L60.959 74.683L64.929 97.252L57.025608 98.451893Z\" fill=\"#26365D\" stroke=\"none\"/><circle cx=\"61\" cy=\"98\" r=\"4\" fill=\"#26365D\" stroke=\"none\"/><path d=\"M9.979 35.452L14.021 28.548L56.959 53.683L49.041 58.317Z\" fill=\"#26365D\" stroke=\"none\"/><path d=\"M10.015444 56.472973L13.984556 49.527027L40.982561 64.954459L33.017439 69.616969Z\" fill=\"#26365D\" stroke=\"none\"/><path d=\"M49.041 58.317L56.959 53.683L60.959 74.683L53.041 79.317Z\" fill=\"#EF8B9D\" stroke=\"none\"/></g></g></g></svg>",
 "reverse": "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"512\" height=\"512\" viewBox=\"0 0 512 512\"><g transform=\"translate(42 27) scale(4.1)\"><g transform=\"translate(0 0) scale(1)\" fill=\"none\" stroke-width=\"8\" stroke-linejoin=\"round\" stroke-linecap=\"butt\"><defs><clipPath id=\"cut0_0\"><path d=\"M-20 -20H130V57.609756L45 107.365854V102.975610L-20 64.926829Z\"/></clipPath></defs><g clip-path=\"url(#cut0_0)\"><path d=\"M61 98L74 64 85 84 94 32L53 8 12 32v60\" stroke=\"#F4EFF4\"/><path d=\"M53.041 79.317L60.959 74.683L64.929 97.252L57.025608 98.451893Z\" fill=\"#F4EFF4\" stroke=\"none\"/><circle cx=\"61\" cy=\"98\" r=\"4\" fill=\"#F4EFF4\" stroke=\"none\"/><path d=\"M9.979 35.452L14.021 28.548L56.959 53.683L49.041 58.317Z\" fill=\"#F4EFF4\" stroke=\"none\"/><path d=\"M10.015444 56.472973L13.984556 49.527027L40.982561 64.954459L33.017439 69.616969Z\" fill=\"#F4EFF4\" stroke=\"none\"/><path d=\"M49.041 58.317L56.959 53.683L60.959 74.683L53.041 79.317Z\" fill=\"#EF8B9D\" stroke=\"none\"/></g></g></g></svg>"
}
static var _textures: Dictionary = {}
static func texture(reverse: bool = true) -> Texture2D:
 var key := "reverse" if reverse else "primary"
 if _textures.has(key): return _textures[key]
 var image := Image.new()
 if image.load_svg_from_string(SVG[key]) != OK: return null
 _textures[key] = ImageTexture.create_from_image(image)
 return _textures[key]
