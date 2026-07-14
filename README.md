# Guide

## Korean
1. [skins](skins) 폴더에 .osk 파일을 넣습니다.
2. [images](images) 폴더에 같은 이름의 이미지 파일을 넣습니다.
   - 예: skin_name.osk + skin_name.jpg
3. [make-osu-skins-collection.bat](make-osu-skins-collection.bat) 파일을 실행합니다.
   - .ps1 파일은 더블클릭으로 실행되지 않을 수 있으므로, .bat 파일로 실행하는 것이 가장 안전합니다.
4. 화면에서 머리 문구를 입력합니다.
   - 여러 줄 입력 가능
   - 끝에 ``[END]`` 를 입력하면 종료됩니다.
5. 이어서 꼬리 문구를 입력합니다.
6. 실행이 끝나면 생성 결과가 [README.md](README.md)로 저장됩니다.

## English
1. Put your .osk files into [skins](skins).
2. Put matching image files into [images](images) with the same base name.
   - Example: skin_name.osk + skin_name.jpg
3. Run [make-osu-skins-collection.bat](make-osu-skins-collection.bat).
   - The .ps1 script may not run by double-clicking in Windows, so using the .bat file is the safest option.
4. Enter the header text in the console.
   - You can enter multiple lines.
   - Type ``[END]`` to finish.
5. Enter the footer text in the next prompt.
6. When the process finishes, the generated output will be saved as [README.md](README.md).

## Notes
- The generator checks whether each .osk file has a matching image file.
- If a pair is missing, it will be listed in the output.
