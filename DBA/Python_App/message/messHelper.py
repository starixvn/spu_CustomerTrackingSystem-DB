import telegram
from config import config


class MessageHelper:
    token_1 = None
    chatID = None
    bot = None

    def __init__(self):
        telegramConfig = config['telegram_channel'];
        self.token_1 = telegramConfig['token']
        self.chatID = telegramConfig['chat_id']
        

    def SendTelegramMessage(self,telegramOpt,message):
        if telegramOpt["token"] and telegramOpt["chat_id"]:
            tele = telegram.Bot(token=telegramOpt["token"]);
            tele.sendMessage(chat_id=telegramOpt["chat_id"], text=message,parse_mode='HTML');

    def SendMessage(self, message):
        self.bot = telegram.Bot(token=self.token_1);
        self.bot.sendMessage(chat_id=self.chatID, text=message,parse_mode='HTML')

    def close(self):
        self.bot.close();
