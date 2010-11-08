DELIMITER ;;
/*!50003 DROP PROCEDURE IF EXISTS `create_wiki` */;;
/*!50003 CREATE*/ /*!50020 DEFINER=`redmine`@`localhost`*/ /*!50003 PROCEDURE `create_wiki`(IN sPrjName VARCHAR(255), IN iAuthorId INT, IN tPageText TEXT)
BEGIN
    DECLARE iPrjId INT DEFAULT 0;
    DECLARE iWikiId INT DEFAULT 0;
    DECLARE iPageId INT DEFAULT 0;
    DECLARE iContentId INT DEFAULT 0;
    DECLARE iDone INT DEFAULT 0;
    DECLARE rCursor CURSOR FOR
      SELECT `id` FROM `wiki_pages` WHERE `wiki_id`=iWikiId;
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET iDone=1;
    
    
    SELECT `id` INTO iPrjId FROM `projects` WHERE `identifier`=sPrjName LIMIT 1;
    IF iPrjId = 0 THEN
      SELECT 'Could not find project';
    ELSE
      
      SELECT `id` INTO iWikiId FROM `wikis` WHERE `project_id`=iPrjId LIMIT 1;
      IF iWikiId = 0 THEN
        
        INSERT INTO `wikis` (`project_id`, `start_page`, `status`) VALUES (iPrjId, "Wiki", 1);
	SELECT LAST_INSERT_ID() INTO iWikiId;
      END IF;
      
      OPEN rCursor;
      FETCH rCursor INTO iPageId;
      WHILE iDone = 0 DO
	DELETE FROM `wiki_contents` WHERE `page_id` = iPageId;
        DELETE FROM `wiki_content_versions` WHERE `page_id` = iPageId;
        FETCH rCursor INTO iPageId;
      END WHILE;
      CLOSE rCursor;
      
      DELETE FROM `wiki_pages` WHERE `wiki_id`=iWikiId;
      
      INSERT INTO `wiki_pages` (`wiki_id`, `title`, `created_on`) VALUES (iWikiId, "Wiki", NOW());
      SELECT LAST_INSERT_ID() INTO iPageId;
      
      INSERT INTO `wiki_contents` (`page_id`, `author_id`, `text`, `updated_on`, `version`) VALUES (iPageId, iAuthorId, tPageText, NOW(), 1);
      SELECT LAST_INSERT_ID() INTO iContentId;
      
      INSERT INTO `wiki_content_versions` (`wiki_content_id`, `page_id`, `author_id`, `data`, `compression`, `updated_on`, `version`) VALUES (iContentId, iPageId, iAuthorId, SUBSTR(COMPRESS(tPageText), 5), 'gzip', NOW(), 1);
    END IF;
END */;;
DELIMITER ;
