#!/usr/bin/env python
"""
This is the main script that will extract reports and then run various
plugins on them.

All reports have to be a a compressed tarfile of type bzip2/gunzip.

This menu system is based on:  http://code.google.com/p/simple-menu-system/

@author    :  Shane Bradley
@contact   :  sbradley@redhat.com
@version   :  2.03
@copyright :  GPLv2
"""
import sys
import logging

import sx
from sx.logwriter import LogWriter
import sxstrata

class ConsoleMenuSystem:
	def __init__(self, title='menu', prompt='$ '):
                # pick your favourite newline character '\r\n' for m$ lusers (or '|\n') for fun
		self.__nl = '\n'
                # The pre and post fix are for your enumeration string: such as a --> "a)"
		self.__prefix = ''
		self.__postfix = ') '

                # 76 = 80 - (3 + 1)
		# max = default screen char width - (# menu item chars + 1 letter char + 1 end of line space)
		self.__maxTextSize = 80 - (len(self.__prefix) + len(self.__postfix) + 1 + len(self.__nl))

		self.__menuTitle = title	# the menu title
		self.__menuPrompt = prompt	# the menu prompt
		self.__menuItemList = []	#list of menu items

	def add_entry(self, key, text, sub=None):
		"""add entries to our menu: key is single A-Z, a-z
		letter choice, no duplicates text is text you want to
		display sub is None for regular function sub is lambda
		function or function for something to happen on press
		if the function returns true, then menu returns,
		otherwise it loops in menu sub is a built
		ConsoleMenuSystem class if you want a sub menu to run
		and return next
		"""
                # Removed the returns after the exception because did not make sense to have them.
		if (not(type(key) in [type('a')] and type(text) in [type('abc')])):
			message = "The key and text parameters must be strings."
                        logging.getLogger(sxstrata.MAIN_LOGGER_NAME).error(message)
			raise Exception(message)

		if (len(key) != 1 or len(text) > self.__maxTextSize):
                #if (len(text) > self.__maxTextSize):
                        # Removed the single character limit
			message = "The text size is %d and is larger than max size %d." %(len(text), self.__maxTextSize)
                        logging.getLogger(sxstrata.MAIN_LOGGER_NAME).error(message)
			raise Exception(message)

		if (ord(key) >= ord('A') and ord(key) <= ord('Z')) or (ord(key) >= ord('a') and ord(key) <= ord('z')):
			# check to avoid duplicate keys
			for x in self.__menuItemList:
				if x['key'] == key:
                                        message = "The keys must be unique to this menu system. This is a duplicate key: %s" %(key)
                                        logging.getLogger(sxstrata.MAIN_LOGGER_NAME).error(message)
					raise Exception(message)

			#TODO: we could add truncation of text if it's too long
			temp = {'key': key, 'text': text, 'sub': sub}
			self.__menuItemList.append(temp)
			return True # happy

		else:
                        message = "Bad key for menu entry."
                        logging.getLogger(sxstrata.MAIN_LOGGER_NAME).error(message)
                        raise Exception(message)



        def write(self, message):
                sys.stdout.write(message)

	def run(self):
		"""
                Runs the menu system and the returns the selected
                letter.
                """
		while True:
                        # print title
			self.write(self.__menuTitle + self.__nl)
			for x in self.__menuItemList:
				self.write(self.__prefix + x['key'] + self.__postfix + x['text'] + self.__nl)
			try:
                                # do safe/smart prompt
				answer = '' # safe
				answer = raw_input(self.__menuPrompt)
			except EOFError: #user pressed ^D
                                self.write("\n")
                                message = "The menu will exit since Control-D was pressed."
                                logging.getLogger(sxstrata.MAIN_LOGGER_NAME).warning(message)
				return False
			except KeyboardInterrupt:
                                self.write("\n")
                                message = "The menu will exit since Control-C was pressed."
                                logging.getLogger(sxstrata.MAIN_LOGGER_NAME).warning(message)
				return False

			# validate answer if the answer size is not greater than 1
			#if (len(answer) != 1):
                        if (not len(answer) > 0):
                                message = "There was no option selected. Please selection a menu option."
                                logging.getLogger(sxstrata.MAIN_LOGGER_NAME).error(message)
                                self.write("\n")
				continue

			# look for answer
			foundMenuOption = False
			for x in self.__menuItemList:
				if (x['key'] == answer):
					foundMenuOption = True
					if (type(x['sub']) in [type(None)]):
						return x['key']
					elif (type(x['sub']) in [type(lambda: True)]):
						# lambda functions that run each time
						# if they return true, you exit menu
						# if they return false, stay in menu
						if x['sub'](): return x['key']
						else: continue

					elif (type(x['sub']) in [type(ConsoleMenuSystem())]):
						#sub menu system
						self.write(self.__nl)
						recurse = x['sub'].run()
						if not(type(recurse) in [type('a')]): recurse = '0'
						return x['key'] + recurse

			if (not foundMenuOption):
                                message = "Invalid menu option selected: %s." %(answer)
                                logging.getLogger(sxstrata.MAIN_LOGGER_NAME).error(message)
                                self.write("\n")
				continue





def printfoo():
	print 'i am printing foo!'
	return False #make it stay and loop

# ###############################################################################
if __name__ == "__main__":
    try:
        # #######################################################################
        # Setup the logger and create config directory
        # #######################################################################

        lwObjSXC = LogWriter(sx.MAIN_LOGGER_NAME,
                             logging.INFO,
                             sx.MAIN_LOGGER_FORMAT,
                             disableConsoleLog=False)

        lwObjSXC = LogWriter(sxstrata.MAIN_LOGGER_NAME,
                             logging.INFO,
                             sxstrata.MAIN_LOGGER_FORMAT,
                             disableConsoleLog=False)
        # #######################################################################
        # Exeute the main function to do the action
        # #######################################################################
        sub = ConsoleMenuSystem('sub menu', 'enter a letter> ')
        sub.add_entry('x', 'this is x')
        sub.add_entry('y', 'this is y')
        sub.add_entry('z', 'this is z')
        sub.add_entry('E', 'Escape this menu', lambda: True)
        sub.add_entry('q', 'choose `q\' to quit')


        thing = ConsoleMenuSystem('main menu\n---------', '\n$ ')
        thing.add_entry('a', 'Choose a')
        thing.add_entry('c', 'Goto SubMenu', sub)
        thing.add_entry('w', 'Loop this menu', lambda: False)
        thing.add_entry('E', 'Escape this menu', lambda: True)
        thing.add_entry('p', 'Do function printfoo() and loop', printfoo)
        thing.add_entry('q', 'Choose `q\' to quit')

        print 'the chosen letter is: ' + str(thing.run())


        #thing = ConsoleMenuSystem('main menu\n---------', '\n$ ')
        #thing.add_entry(1, 'Goto SubMenu', sub)
        #thing.add_entry('addd', 'Choose a')
        """
        #example 2
        menua = ConsoleMenuSystem('menu a: animals\n---------------')
        menua.add_entry('a', 'a is for alligator')
        menua.add_entry('b', 'b is for baboon')
        menua.add_entry('c', 'c is for cheetah')


        menub = ConsoleMenuSystem('menu b: food\n------------')
        menub.add_entry('a', 'a is for apple')
        menub.add_entry('b', 'b is for banana')
        menub.add_entry('c', 'c is for carrot')


        menua.add_entry('x', 'goto food menu', menub)
        menub.add_entry('x', 'goto animals menu', menua)

        menua.add_entry('q', 'choose `q\' to quit')
        menub.add_entry('q', 'choose `q\' to quit')

        menua.run()
        """
        # #######################################################################
    except KeyboardInterrupt:
        message =  "This script will exit since control-c was executed by end user."
        logging.getLogger(sxstrata.MAIN_LOGGER_NAME).error(message)
        sys.exit(2)
    sys.exit()
# ###############################################################################


