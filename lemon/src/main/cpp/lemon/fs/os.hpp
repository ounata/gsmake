#ifndef LEMON_FS_OS_HPP
#define LEMON_FS_OS_HPP

#include <memory>

#include <lemon/fs/filepath.hpp>
#include <lemon/fs/dir_iterator.hpp>

namespace lemon{ namespace fs{

    /**
     * get current working directory
     */
    filepath current_path(std::error_code &e) noexcept;

    inline filepath current_path()
    {
        std::error_code err;

        auto result = current_path(err);

        if (err)
        {
            throw std::system_error(err);
        }

        return result;
    }

    /**
     * set current working directory
     */
    void current_path(const filepath & path,std::error_code &e) noexcept ;


    inline void current_path(const filepath& path)
    {
        std::error_code err;

        current_path(path,err);

        if (err)
        {
            throw std::system_error(err);
        }
    }

    inline filepath absolute(const filepath & path,std::error_code &err) noexcept
    {
        if(path.has_root_directory())
        {
            return path;
        }

        auto root_path = current_path(err);

        return root_path /= path;
    }

    inline filepath absolute(const filepath & path)
    {
        std::error_code err;

        auto newpath = absolute(path,err);

        if (err)
        {
            throw std::system_error(err);
        }

        return newpath;
    }

    bool exists(const filepath& path) noexcept ;

    /**
    * create new directory
    */
    void create_directory(const filepath& path,std::error_code & err) noexcept ;

    inline void create_directory(const filepath& path)
    {
        std::error_code err;

        create_directory(path,err);

        if (err)
        {
            throw std::system_error(err);
        }
    }


    inline void create_directories(const filepath &path, std::error_code &err)
    {
        if(path.has_parent())
        {
            auto parent = path.parent_path();

            if(!exists(parent))
            {
                create_directories(parent,err);

                if(err) return;
            }
        }

		if(!exists(path)) 
		{
			create_directory(path, err);
		}
      
    }

    inline void create_directories(const filepath &path)
    {
        std::error_code err;

        create_directories(path, err);

        if (err)
        {
            throw std::system_error(err);
        }
    }

    void create_symlink(const filepath& from,const filepath& to,std::error_code & err) noexcept ;

    inline void create_symlink(const filepath& from,const filepath& to)
    {
        std::error_code err;

        create_symlink(from,to,err);

        if (err)
        {
            throw std::system_error(err);
        }
    }


    bool is_directory(const filepath & source) noexcept ;

    void remove_file(const filepath & path ,std::error_code &e) noexcept ;

    inline void remove_file(const filepath & path )
    {
        std::error_code err;

        remove_file(path,err);

        if (err)
        {
            throw std::system_error(err);
        }
    }

    inline void remove_directories(const filepath & path, std::error_code &err)
    {
        try
        {
            auto iter = directory_iterator(absolute(path));

            if (err)
            {
                return;
            }

            while (iter.has_next())
            {
                auto entry = iter().string();

                if (entry == "." || entry == "..") continue;

                auto child = path / entry;

                if (is_directory(child))
                {
                    remove_directories(child, err);

                    if (err)
                    {
                        return;
                    }

                    continue;
                }

                remove_file(child, err);

                if (err)
                {
                    return;
                }
            }
        }
        catch (const std::system_error &e)
        {
            err = e.code();
        }

        remove_file(path, err);
    }

    inline void remove_directories(const filepath & path)
    {
        std::error_code err;

        remove_directories(path, err);

        if (err)
        {
            throw std::system_error(err);
        }
    }
}}

#endif //LEMON_FS_OS_HPP
