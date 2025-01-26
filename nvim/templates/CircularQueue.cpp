#include <array>
#include <cstddef>
#include <cstdlib>
#include <utility>

template <typename T, std::size_t Capacity>
class CircularQueue {
 public:
  void push(const T& value) {
    queue_[back_] = value;
    back_ = (back_ + 1) % Capacity;
  }

  template <typename... Args>
  void emplace(Args&&... args) {
    queue_[back_] = T(std::forward<Args>(args)...);
    back_ = (back_ + 1) % Capacity;
  }

  T& front() { return queue_[front_]; }

  const T& front() const { return queue_[front_]; }

  void pop() { front_ = (front_ + 1) % Capacity; }

  [[nodiscard]] bool empty() const noexcept { return front_ == back_; }

  std::size_t size() const noexcept {
    return (static_cast<int>(back_) - static_cast<int>(front_) + Capacity) %
           Capacity;
  }

 private:
  std::size_t front_{};
  std::size_t back_{};

  std::array<T, Capacity> queue_;
};
