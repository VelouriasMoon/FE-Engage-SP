# FE-Engage-SP
Substance Painter shader and more for Fire Emblem Engage
![image](https://github.com/user-attachments/assets/7be87b00-7872-49e1-bc19-1b2da569ec25)


## Navigation
- [Version 2.0](#new-in-version-20)
- [Setup](#setup)
- [Usage](#usage)
- [Export](#export)

## New in Version 2.0
Version 2.0 now includes Hair and Eye Shaders for a more complete preview.  
Eye shaders are pretty much exclusively controlled in the shader settings tab for now and more mostly there for now.   
For working with the Hair shader I reccomend changing the UV Padding in the "Texture Set Settings" tab for your hair mat from "3D Space" to "UV Space.  
![image](https://github.com/user-attachments/assets/bfa64107-d542-4b90-ac8b-f4d52b52a0a7)

## Setup
1. Download or Clone the repo
2. Extract the zip to a location of your choice
3. In Substance painter go to Edit > Settings > Shelf/Libraries
4. Add the new shelf by setting the name and path clicking the "+" button to add  
![image](https://github.com/user-attachments/assets/7945a84e-aa7b-429d-8808-cec15d123677)

## Usage
Start by making a new project under File > New, then pick the "FE-Engage" or "FE-Engage-V2" Template and setting the normal map format to OpenGL  
![image](https://github.com/user-attachments/assets/2403e4f7-6dbf-4ee5-a5ec-ac959dbe002c)  

Import textures(if needed) by dragging the images into the Shelf/Asset tab. Making sure that the normal map is properly formated, aka blue not red, and the multi map is split into it's sub components.  
Usually Red - Roughness, Green - Metal, Blue - AO, Alpha - Color mask for class models. The Repo also includes python scripts to help automate this by just dragging and dropping the images onto the script.
these scripts require Pillow installed. Set the type from undefined to Texture and import them to your project not your shelf.  
![image](https://github.com/user-attachments/assets/504b69c2-ecdf-463e-be87-8bb1e58df2ff)

In the Texture Set List make sure your MtDress or other cloth material is set to Main Shader and your MtSkin is set to Skin Shader. these can be changed by just clicking on the shader name.  
![image](https://github.com/user-attachments/assets/0f5d44c7-46b8-422b-be46-2eb9383af71f)

Finally if you're working off existing textures add a fill layer and fill out the channels with their respective textures that you imported earlier. Once that's all done you should have a model that something like this.  
![image](https://github.com/user-attachments/assets/050a0512-500d-442b-ae4f-25bd149ef739)

with all that done you are now ready to start texturing with the Engage Shader. if you're working with existing textures you can use the material picker tool on your brush to sample parts of the original texture.
this will allow you to paint textures that match where you sampled, you can even tweak things like the color. This is great if there's parts like metal you wish to use elsewhere or on new models, just remember to 
enable all the channels on the brush before using the picker. lastly the height channel, while not part of engage's shader is used in substance painter to allow you to draw on normal map detail without baking.

## Export
Once your textures are done it's time to export. Luckily Substance Painter makes this easy too. go to File > Export Textures. Set the Output Template to "Engage" even if it says "Engage (from cache)" it's safer to set 
it to Engage to make sure it's using the latest version of the export template. Enable/Disable all the texture setup you do or don't want exported. Then you are ready to hit the Export button, SP will export all your textures 
game ready for import into unity. Once it's done exporting the textures click the "Open Output Folder" at the top of the export window in the List of Exports tab to get the images you need to import into unity.

one limit of this is that texture sets will all have their own export, so if you want to have both the Dress and Skin textures in the same image like how engage does you'll have to do some post image editing to splice the 2 together.
Or just leave them as is and use them as sperate textures in unity.
