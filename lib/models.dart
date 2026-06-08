import 'package:flutter/material.dart';

class UserProfile {
  final String username;
  final Color color;
  final int? avatarIndex;

  const UserProfile({required this.username, required this.color, this.avatarIndex});
}

const profiles = [
  UserProfile(username: 'alex_brt',    color: Colors.pinkAccent,      avatarIndex: 12),
  UserProfile(username: 'Sarah_M',     color: Colors.cyanAccent,       avatarIndex: 45),
  UserProfile(username: 'jo_99',       color: Colors.yellowAccent,     avatarIndex: null),
  UserProfile(username: 'YukiChan',    color: Colors.purpleAccent,     avatarIndex: 78),
  UserProfile(username: 'devmaster42', color: Colors.greenAccent,      avatarIndex: 130),
  UserProfile(username: 'CoolKid',     color: Colors.orangeAccent,     avatarIndex: null),
  UserProfile(username: 'nightowl__',  color: Colors.lightBlueAccent,  avatarIndex: 200),
  UserProfile(username: 'StarGazer',   color: Colors.tealAccent,       avatarIndex: 33),
  UserProfile(username: 'tech_fan',    color: Colors.pinkAccent,       avatarIndex: 99),
  UserProfile(username: 'MusicLvr',    color: Colors.cyanAccent,       avatarIndex: null),
  UserProfile(username: 'xXDarkXx',   color: Colors.purpleAccent,     avatarIndex: 150),
  UserProfile(username: 'flutterfan', color: Colors.greenAccent,      avatarIndex: 17),
  UserProfile(username: 'Watcher99',   color: Colors.orangeAccent,     avatarIndex: 210),
  UserProfile(username: 'lila_r',      color: Colors.yellowAccent,     avatarIndex: null),
  UserProfile(username: 'mo_streams',  color: Colors.lightBlueAccent,  avatarIndex: 64),
  UserProfile(username: 'Lucas_off',   color: Colors.tealAccent,       avatarIndex: 188),
  UserProfile(username: 'noemie.live', color: Colors.pinkAccent,       avatarIndex: 7),
  UserProfile(username: 'raptor77',    color: Colors.cyanAccent,       avatarIndex: null),
  UserProfile(username: 'Clem_B',      color: Colors.orangeAccent,     avatarIndex: 240),
  UserProfile(username: 'kev_gaming',  color: Colors.greenAccent,      avatarIndex: 55),
  UserProfile(username: 'ZoeR',        color: Colors.purpleAccent,     avatarIndex: null),
  UserProfile(username: 'theovlive',   color: Colors.yellowAccent,     avatarIndex: 120),
];

class ChatMessage {
  final String username;
  final String text;
  final Color color;
  final bool isOwn;
  final int? avatarIndex;

  const ChatMessage({
    required this.username,
    required this.text,
    required this.color,
    this.isOwn = false,
    this.avatarIndex,
  });
}

const simulatedMessages = [
  '🔥🔥🔥',
  'Trop bien !',
  'Bonjour depuis Paris !',
  'Premier !',
  'C\'est incroyable',
  'Tu nous vois ?',
  '❤️❤️',
  'Trop fort',
  'Super stream',
  'Allez !!!',
  'Salut tout le monde !',
  '👋',
  'Magnifique !',
  'Encore !',
  'GG',
  '🎉🎉🎉',
  'oh là là',
  'meilleur live ever',
  '💯💯',
  'trop drôle',
  'j\'adore ce live',
  'continuez comme ça !',
  'trop stylé 😍',
];

const heartEmojis = ['❤️', '🧡', '💛', '💖', '💗', '💜', '🤍'];
