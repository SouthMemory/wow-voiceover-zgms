# VoiceOver for World of Warcraft specialized for 战歌魔兽 with 中文语音包

## 和原版本有何不同

### 提供中文语音包下载
- 百度网盘：https://pan.baidu.com/s/1jPWSehhTUhkK1GYtGhLb7w 提取码: zgms
- Q群：948016495
- 计划提供其他版本的语音：亮剑版本、三国版本，蜡笔小新版本，水浒版本

### 增加或修改一些配置
- 修改配置：3.35版本默认为使用音乐声道进行播放
- 增加配置：接受任务时，是否播放任务语音
- 增加配置：玩家在执行任务的过程中，系统自动识别并播放对应任务的语音

### 对插件界面进行汉化
- 如题

### 在任务追踪栏，增加语音播放按键
- 如题


# 下面的信息为来自于原项目

## v2: https://allvoice.ai
Contribute voices on [allvoice.ai](https://allvoice.ai) so I can give each NPC a unique AI voicemodel to power their dialog. The top rated voice for each NPC will be used. 


### [voiceover discord](https://discord.gg/VdhUmA8ZCt)
### [allvoice code](https://github.com/allvoice/allvoice-website)

## Overview
- tts cli to create audio files for quests and gossip text.
- in game addon for playing generated voiceovers

- cli uses data fetched from a local MySQL database and ElevenLabs tts for speech


## Below is for developers only. Go to [releases](https://github.com/mrthinger/wow-voiceover/releases) if youre looking to install the addon.

## Requirements
- python 3.10+
- docker (for the database)

## Installation
1. Make a python virtual environment. (make sure to source it after creating)
```bash
python -m venv .venv
```
2. Install the required packages.
```bash
pip install -r requirements.txt
```
3. Copy the .env.example file to .env and fill in your ElevenLabs API Key and database credentials. The included database values are fine if you're going to use the docker-compose file.
```bash
cp .env.example .env
```
4. Start the MySQL DB
```bash
docker compose up -d
```
5. Seed the MySQL DB
```bash
python cli-main.py init-db
```

## Voice Setup
The generation scripts assume you have voices created in Elevenlabs named in the format `race-gender`. For the exact races the script checks your elevenlabs account for, refer to `tts_cli\consts.py`. Gender will always either be `male` or `female`. ex: `orc-male`. You will need to create your own voice clones. A good place to get samples is @ https://www.wowhead.com/sounds/npc-greetings/name:orc 
## Usage
To use the interactive CLI tool, run the following command:

```bash
python cli-main.py
```

### Language Client Selection
Currently there are no voice translations available for languages other than english. However, if you want to use the addon with a non English client, you can still do so by creating the lookup tables in the client's respective language.

To create the lookup tables, you can use the following command, with `LANGUAGE_CODE` representing the required language for the client:
```bash
python cli-main.py gen_lookup_tables --lang=LANGUAGE_CODE
```
The default selection, when no language code is provided, is English. Please be aware that the quality of text completion for translations in languages other than English can vary significantly.

The following language codes are supported:
| Language Code | Language |
| ------------- | ------- |
| enUS          | English |
| enGB          | English |
| koKR          | Korean |
| frFR          | French |
| deDE          | German |
| zhCN          | Simplified Chinese |
| zhTW          | Traditional Chinese |
| esES          | European Spanish |
| esMX          | Mexican Spanish |
| ruRU          | Russian |

## Output
The generated TTS audio files will be saved in the sounds folder, with separate subfolders for quests and gossip. Lookup tables and sound length tables will also be generated for use in the addon. 

## Addon Install
Copy over the `generated` folder to the VoiceOverData_Vanilla folder, then the VoiceOver and VoiceOverData_Vanilla folder to `World of Warcraft/_classic_era_/Interface/AddOns`. Alternatively, you can syslink instead of copying for faster development.
Example syslink:
```bash
export WOW_DIR=PATH_OF_YOUR_WOW_DIR
ln -s ./VoiceOver "$WOW_DIR/_classic_era_/Interface/AddOns"
ln -s ./VoiceOver_Vanilla "$WOW_DIR/_classic_era_/Interface/AddOns"
```
## Contributing
If you want to contribute to this project, please feel free to open an issue or submit a pull request.

# CLI Docs

## Dataframe Schema

The dataframe schema before calling the `preprocess_dataframe` function consists of the following columns:

| Column        | Description                                                  |
|---------------|--------------------------------------------------------------|
| `source`      | Indicates the type of interaction, can be 'accept', 'progress', 'complete', or 'gossip' |
| `quest`       | The quest ID or empty string if it's a gossip interaction    |
| `text`        | The text template content of the interaction                           |
| `DisplayRaceID` | The race ID of the NPC involved in the interaction          |
| `DisplaySexID`  | The gender ID of the NPC involved in the interaction        |
| `name`        | The name of the NPC involved in the interaction               |
| `type`        | The type of the NPC involved in the interaction ('creature', 'gameobject', or 'item') |
| `id`          | The creature/gameobject/item ID of the NPC involved in the interaction |

`DisplayRaceID = -1` is used for interactions with inanimate NPCs: gameobjects, items etc. It's mapped to a voice called "narrator" in `RACE_DICT`.

## New Fields Added by `preprocess_dataframe`

The `preprocess_dataframe` function adds the following new fields to the dataframe:

| Column                   | Description                                                  |
|--------------------------|--------------------------------------------------------------|
| `race`                   | The race of the NPC, mapped from `DisplayRaceID` using `RACE_DICT` |
| `gender`                 | The gender of the NPC, mapped from `DisplaySexID` using `GENDER_DICT` |
| `voice_name`             | The voice name, which is a combination of the race and gender fields |
| `templateText_race_gender` | A combination of the text, race, and gender fields          |
| `templateText_race_gender_hash` | A hash of the `templateText_race_gender` field          |
| `cleanedText` | `text` after rendering template |
