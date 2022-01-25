import telegram
from config import config


class MessageHelper:
    token = None
    chatID = None
    bot = None

    def __init__(self):
        telegramConfig = config['telegram_channel_test'];
        self.token = telegramConfig['token']
        self.chatID = telegramConfig['chat_id']
        self.bot = telegram.Bot(token=self.token);

    def sendMessage(self, message):
        self.bot.sendMessage(chat_id=self.chatID, text=message,parse_mode='HTML')

    def close(self):
        self.bot.close();
